import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/condition.dart';
import '../../services/sleep_session_state_service.dart';
import '../../services/database_service.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/sleeping_ui.dart';
import '../../widgets/awaken_confirmation_dialog.dart';
import '../../widgets/exit_session_dialog.dart';
import 'lseq_screen.dart';

class FixedHypnosisScreen extends StatefulWidget {
  final String? participantId;
  final int? nightNumber;
  final Condition? condition;
  final int? sssLevel;
  final String? sessionId; // For resuming existing session

  const FixedHypnosisScreen({
    super.key,
    this.participantId,
    this.nightNumber,
    this.condition,
    this.sssLevel,
    this.sessionId,
  });

  @override
  State<FixedHypnosisScreen> createState() => _FixedHypnosisScreenState();
}

class _FixedHypnosisScreenState extends State<FixedHypnosisScreen> {
  final _stateService = SleepSessionStateService();
  final _databaseService = DatabaseService();
  final _audioService = AudioPlayerService();
  bool _isInitializing = true;
  DateTime? _startTime;
  String? _sessionId;
  PlayerState _playerState = PlayerState.stopped;
  bool _isAudioCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAndStartTracking();
    
    // Listen to player state changes
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

  Future<void> _initializeAndStartTracking() async {
    try {
      // Check if we're resuming an existing session or creating a new one
      if (widget.sessionId != null) {
        // Resuming existing session
        _sessionId = widget.sessionId!;
      } else {
        // Create new nightly session NOW when tracking actually starts
        final session = await _databaseService.createNightlySession(
          participantId: widget.participantId!,
          nightNumber: widget.nightNumber!,
          condition: widget.condition!,
        );

        _sessionId = session.id;

        // Save SSS response
        await _databaseService.savePreSleepResponses(
          session.id,
          {'sleepiness_level': widget.sssLevel!},
        );
      }

      // Start sleep tracking
      final started = await _stateService.startTracking(_sessionId!);
      
      if (started) {
        setState(() {
          _startTime = DateTime.now();
          _isInitializing = false;
        });
        
        // Start audio playback
        final audioStarted = await _audioService.playFromAsset('audio/fixed_hypnosis.mp3');
        if (!audioStarted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file not found. Please add fixed_hypnosis.mp3 to assets/audio/'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Failed to start tracking');
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start sleep tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
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

    if (confirmed == true && mounted && _sessionId != null) {
      // Stop audio and tracking
      await _audioService.stop();
      await _stateService.stopTracking(_sessionId!);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LseqScreen(sessionId: _sessionId!),
          ),
        );
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

    if (confirmed == true && _sessionId != null) {
      // Stop audio and tracking before exiting
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
