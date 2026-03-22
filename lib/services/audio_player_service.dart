import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as audio_session;

/// Service to manage audio playback for hypnosis sessions
class AudioPlayerService {
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  String? _currentPath;
  bool _isAsset = false; // Track if source is asset or file
  bool _audioSessionConfigured = false;
  
  AudioPlayerService() {
    _audioPlayer = AudioPlayer();
    _configureAudioSession();
  }
  
  /// Configure audio session for background playback
  Future<void> _configureAudioSession() async {
    if (_audioSessionConfigured) return;
    
    try {
      final session = await audio_session.AudioSession.instance;
      // Use the music preset for background audio playback
      await session.configure(const audio_session.AudioSessionConfiguration(
        avAudioSessionCategory: audio_session.AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: audio_session.AVAudioSessionMode.defaultMode,
        androidAudioAttributes: audio_session.AndroidAudioAttributes(
          contentType: audio_session.AndroidAudioContentType.music,
          usage: audio_session.AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      await session.setActive(true);
      _audioSessionConfigured = true;
      print('Audio session configured for background playback');
    } catch (e) {
      print('Error configuring audio session: $e');
    }
  }

  /// Initialize and play audio from assets
  Future<bool> playFromAsset(String assetPath) async {
    try {
      _isInitialized = true;
      _currentPath = assetPath;
      _isAsset = true;
      await _audioPlayer.play(AssetSource(assetPath));
      return true;
    } catch (e) {
      print('Error playing audio: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Play audio from asset and wait for completion
  Future<void> playAssetAndWait(String assetPath) async {
    _isInitialized = true;
    _currentPath = assetPath;
    _isAsset = true;
    
    // Start playback
    await _audioPlayer.play(AssetSource(assetPath));
    
    // Wait a moment for duration to be available
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get the duration
    Duration? duration = await _audioPlayer.getDuration();
    
    // If we couldn't get duration, try again
    if (duration == null || duration.inMilliseconds == 0) {
      await Future.delayed(const Duration(seconds: 1));
      duration = await _audioPlayer.getDuration();
    }
    
    // If still no duration, use position-based detection with timeout
    if (duration == null || duration.inMilliseconds == 0) {
      print('Could not get duration for $assetPath, using position-based detection');
      await _waitForCompletionByPosition();
      return;
    }
    
    print('Audio duration: ${duration.inSeconds}s for $assetPath');
    
    // Poll position until we're at the end
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final position = await _audioPlayer.getCurrentPosition();
      final state = _audioPlayer.state;
      
      // Check if completed
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        print('Audio completed via state check');
        break;
      }
      
      // Check if position is at or near the end
      if (position != null && duration != null) {
        if (position.inMilliseconds >= duration.inMilliseconds - 200) {
          print('Audio completed via position check');
          break;
        }
      }
      
      // Safety check: if not playing and position is 0, something went wrong
      if (state != PlayerState.playing && (position == null || position.inMilliseconds == 0)) {
        print('Audio stopped unexpectedly');
        break;
      }
    }
  }
  
  /// Wait for completion by monitoring position (fallback method)
  Future<void> _waitForCompletionByPosition() async {
    Duration? lastPosition;
    int samePositionCount = 0;
    
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final position = await _audioPlayer.getCurrentPosition();
      final state = _audioPlayer.state;
      
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        break;
      }
      
      // If position hasn't changed for 2 seconds, assume complete
      if (position == lastPosition) {
        samePositionCount++;
        if (samePositionCount >= 4) { // 4 * 500ms = 2 seconds
          print('Audio assumed complete (position stopped changing)');
          break;
        }
      } else {
        samePositionCount = 0;
      }
      lastPosition = position;
    }
  }

  /// Play audio from file and wait for completion
  Future<void> playFileAndWait(String filePath) async {
    _isInitialized = true;
    _currentPath = filePath;
    _isAsset = false;
    
    // Start playback
    await _audioPlayer.play(DeviceFileSource(filePath));
    
    // Wait a moment for duration to be available
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get the duration
    Duration? duration = await _audioPlayer.getDuration();
    
    // If we couldn't get duration, try again
    if (duration == null || duration.inMilliseconds == 0) {
      await Future.delayed(const Duration(seconds: 1));
      duration = await _audioPlayer.getDuration();
    }
    
    // If still no duration, use position-based detection
    if (duration == null || duration.inMilliseconds == 0) {
      print('Could not get duration for $filePath, using position-based detection');
      await _waitForCompletionByPosition();
      return;
    }
    
    print('Audio duration: ${duration.inSeconds}s for $filePath');
    
    // Poll position until we're at the end
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final position = await _audioPlayer.getCurrentPosition();
      final state = _audioPlayer.state;
      
      // Check if completed
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        print('Audio completed via state check');
        break;
      }
      
      // Check if position is at or near the end
      if (position != null && duration != null) {
        if (position.inMilliseconds >= duration.inMilliseconds - 200) {
          print('Audio completed via position check');
          break;
        }
      }
      
      // Safety check
      if (state != PlayerState.playing && (position == null || position.inMilliseconds == 0)) {
        print('Audio stopped unexpectedly');
        break;
      }
    }
  }

  /// Initialize and play audio from local file path
  Future<bool> playFromFile(String filePath) async {
    try {
      _isInitialized = true;
      _currentPath = filePath;
      _isAsset = false; // Mark as file source
      await _audioPlayer.play(DeviceFileSource(filePath));
      return true;
    } catch (e) {
      print('Error playing audio from file: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Pause audio playback
  Future<void> pause() async {
    if (_isInitialized) {
      await _audioPlayer.pause();
    }
  }

  /// Resume audio playback or replay from start if completed
  Future<void> resume() async {
    if (_isInitialized) {
      // If audio is completed, replay from the beginning using correct source
      if (_audioPlayer.state == PlayerState.completed && _currentPath != null) {
        if (_isAsset) {
          await _audioPlayer.play(AssetSource(_currentPath!));
        } else {
          await _audioPlayer.play(DeviceFileSource(_currentPath!));
        }
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  /// Stop audio playback
  Future<void> stop() async {
    if (_isInitialized) {
      await _audioPlayer.stop();
    }
  }

  /// Restart audio playback from the beginning
  Future<void> restart() async {
    if (_isInitialized && _currentPath != null) {
      await _audioPlayer.stop();
      if (_isAsset) {
        await _audioPlayer.play(AssetSource(_currentPath!));
      } else {
        await _audioPlayer.play(DeviceFileSource(_currentPath!));
      }
    }
  }

  /// Get current player state
  Stream<PlayerState> get playerStateStream => _audioPlayer.onPlayerStateChanged;

  /// Get current position
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  /// Get audio duration
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;
  
  /// Get completion events
  Stream<void> get onComplete => _audioPlayer.onPlayerComplete;

  /// Check if audio is currently playing (not paused or completed)
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  
  /// Check if audio playback is available (playing, paused, or completed)
  bool get hasAudio => _isInitialized;

  /// Dispose of the audio player
  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}
