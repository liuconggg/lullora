import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/sleep_session_state_service.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/sleeping_ui.dart';
import '../../widgets/awaken_confirmation_dialog.dart';
import '../../widgets/exit_session_dialog.dart';
import 'lseq_screen.dart';

class PersonalizedHypnosisScreen extends StatefulWidget {
  final String? sessionId; // Optional - for dynamic hypnosis from setup or for resuming
  final String? audioFilePath; // Optional: for dynamic audio

  const PersonalizedHypnosisScreen({
    super.key,
    this.sessionId,
    this.audioFilePath,
  });

  @override
  State<PersonalizedHypnosisScreen> createState() => _PersonalizedHypnosisScreenState();
}

class _PersonalizedHypnosisScreenState extends State<PersonalizedHypnosisScreen> {
  final _stateService = SleepSessionStateService();
  final _audioService = AudioPlayerService();
  bool _isInitializing = true;
  DateTime? _startTime;
  PlayerState _playerState = PlayerState.stopped;
  bool _isAudioCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAndStartTracking();
    
    // Listen to player state changes if audio playback is enabled
    if (widget.audioFilePath != null) {
      _audioService.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _playerState = state;
            // Mark audio as completed when it stops after playing
            if (state == PlayerState.completed) {
              _isAudioCompleted = true;
            }
          });
        }
      });
    }
  }

  Future<void> _initializeAndStartTracking() async {
    // Check if we have a sessionId (for resuming) or if this is just audio preview
    if (widget.sessionId != null) {
      // Resume mode: Start sleep tracking
      final started = await _stateService.startTracking(widget.sessionId!);
      
      if (!started) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start sleep tracking. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
          return;
        }
      }
    }
    
    // Set start time and play audio
    setState(() {
      _startTime = DateTime.now();
      _isInitializing = false;
    });
    
    // Start audio playback if audio file is provided
    if (widget.audioFilePath != null) {
      final audioStarted = await _audioService.playFromFile(widget.audioFilePath!);
      if (!audioStarted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play audio file'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _handleAwaken() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AwakenConfirmationDialog(),
    );

    if (confirmed == true && mounted) {
      // Stop audio if playing
      if (widget.audioFilePath != null) {
        await _audioService.stop();
      }
      
      // Stop tracking only if we have a sessionId
      if (widget.sessionId != null) {
        await _stateService.stopTracking(widget.sessionId!);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LseqScreen(sessionId: widget.sessionId!),
            ),
          );
        }
      } else {
        // No session - navigate back to home (pop all screens until root)
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  Future<bool> _handleBackButton() async {
    // Show exit confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ExitSessionDialog(),
    );

    if (confirmed == true) {
      // Stop audio and tracking before exiting
      if (widget.audioFilePath != null) {
        await _audioService.stop();
      }
      
      if (widget.sessionId != null) {
        await _stateService.stopTracking(widget.sessionId!);
      }
      
      return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _startTime == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
          isAudioPlaying: widget.audioFilePath != null && _playerState == PlayerState.playing,
          isAudioCompleted: _isAudioCompleted,
          onPauseAudio: widget.audioFilePath != null ? _handlePauseAudio : null,
          onResumeAudio: widget.audioFilePath != null ? _handleResumeAudio : null,
          onRestartAudio: widget.audioFilePath != null ? _handleRestartAudio : null,
        ),
      ),
    );
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
  void dispose() {
    if (widget.audioFilePath != null) {
      _audioService.dispose();
    }
    super.dispose();
  }
}
