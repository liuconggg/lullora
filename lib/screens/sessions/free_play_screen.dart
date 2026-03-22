import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/sleep_session_state_service.dart';
import '../../services/audio_player_service.dart';
import '../../services/dynamic_hypnosis_storage_service.dart';
import '../../services/database_service.dart';
import '../../models/dynamic_hypnosis_config.dart';
import '../../widgets/sleeping_ui.dart';
import '../../widgets/awaken_confirmation_dialog.dart';
import '../../widgets/exit_session_dialog.dart';
import '../../models/condition.dart';

class FreePlayScreen extends StatefulWidget {
  final String participantId;
  final bool isFixedAudio;
  final String? audioAssetPath; // For fixed audio from assets
  final String? audioStoragePath; // For personalized audio from Supabase
  final String? sessionTitle;

  const FreePlayScreen({
    super.key,
    required this.participantId,
    required this.isFixedAudio,
    this.audioAssetPath,
    this.audioStoragePath,
    this.sessionTitle,
  });

  @override
  State<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends State<FreePlayScreen> {
  final _stateService = SleepSessionStateService();
  final _audioService = AudioPlayerService();
  final _storageService = DynamicHypnosisStorageService();
  final _databaseService = DatabaseService();
  
  bool _isInitializing = true;
  DateTime? _startTime;
  String? _sessionId;
  String? _localAudioPath;
  PlayerState _playerState = PlayerState.stopped;
  bool _isAudioCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAndStart();
    
    // Listen to player state changes
    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          // Track when audio completes
          if (state == PlayerState.completed) {
            _isAudioCompleted = true;
          }
        });
      }
    });
  }

  Future<void> _initializeAndStart() async {
    try {
      // Create a "free session" entry for Asleep tracking
      // Use night_number = 0 to indicate free session
      final session = await _databaseService.createNightlySession(
        participantId: widget.participantId,
        nightNumber: 0, // Free session marker
        condition: widget.isFixedAudio ? Condition.fixed : Condition.personalized,
      );
      
      _sessionId = session.id;
      
      // Start sleep tracking
      final started = await _stateService.startTracking(_sessionId!);
      
      if (!started) {
        throw Exception('Failed to start sleep tracking');
      }
      
      // Prepare audio
      if (widget.isFixedAudio && widget.audioAssetPath != null) {
        // Play from asset
        setState(() {
          _startTime = DateTime.now();
          _isInitializing = false;
        });
        await _audioService.playFromAsset(widget.audioAssetPath!);
      } else if (widget.audioStoragePath != null) {
        // Download from Supabase and play
        final config = DynamicHypnosisConfig(
          characterChoice: widget.sessionTitle ?? 'personalized',
          goal: 'free_play',
          voiceId: '',
          voiceName: '',
        );
        
        final localPath = await _storageService.downloadAudioFromStorage(
          storagePath: widget.audioStoragePath!,
          config: config,
        );
        
        if (localPath != null) {
          _localAudioPath = localPath;
          setState(() {
            _startTime = DateTime.now();
            _isInitializing = false;
          });
          await _audioService.playFromFile(localPath);
        } else {
          throw Exception('Failed to download audio');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleAwaken() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AwakenConfirmationDialog(),
    );

    if (confirmed == true && mounted && _sessionId != null) {
      // Stop audio
      await _audioService.stop();
      
      // Stop tracking
      await _stateService.stopTracking(_sessionId!);
      
      // Mark as completed
      await _stateService.markCompleted(_sessionId!);
      
      if (mounted) {
        // Show completion message and return to sessions
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session completed! Sleep data recorded.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _handleBackButton() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ExitSessionDialog(),
    );

    if (confirmed == true && _sessionId != null) {
      await _audioService.stop();
      await _stateService.stopTracking(_sessionId!);
      return true;
    }
    
    return false;
  }

  Future<void> _handlePauseAudio() async {
    await _audioService.pause();
  }

  Future<void> _handleResumeAudio() async {
    await _audioService.resume();
  }

  Future<void> _handleRestartAudio() async {
    await _audioService.restart();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _startTime == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Preparing your session...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: SleepingUI(
          startTime: _startTime!,
          onAwaken: _handleAwaken,
          isHypnosisSession: true,
          isAudioPlaying: _playerState == PlayerState.playing,
          isAudioCompleted: _isAudioCompleted,
          onPauseAudio: _handlePauseAudio,
          onResumeAudio: _handleResumeAudio,
          onRestartAudio: _handleRestartAudio,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
