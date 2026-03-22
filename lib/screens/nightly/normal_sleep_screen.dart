import 'package:flutter/material.dart';
import '../../models/condition.dart';
import '../../services/sleep_session_state_service.dart';
import '../../services/database_service.dart';
import '../../widgets/sleeping_ui.dart';
import '../../widgets/awaken_confirmation_dialog.dart';
import '../../widgets/exit_session_dialog.dart';
import 'lseq_screen.dart';

class NormalSleepScreen extends StatefulWidget {
  final String? participantId;
  final int? nightNumber;
  final Condition? condition;
  final int? sssLevel;
  final String? sessionId; // For resuming existing session

  const NormalSleepScreen({
    super.key,
    this.participantId,
    this.nightNumber,
    this.condition,
    this.sssLevel,
    this.sessionId,
  });

  @override
  State<NormalSleepScreen> createState() => _NormalSleepScreenState();
}

class _NormalSleepScreenState extends State<NormalSleepScreen> {
  final _stateService = SleepSessionStateService();
  final _databaseService = DatabaseService();
  bool _isInitializing = true;
  DateTime? _startTime;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initializeAndStartTracking();
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
      } else {
        throw Exception('Failed to start tracking');
      }
    } catch (e) {
      // Handle error - show error message
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
      // Stop tracking and navigate to questionnaire
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
      // Stop tracking before exiting
      await _stateService.stopTracking(_sessionId!);
      return true;
    }
    
    return false; // Don't allow back navigation
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
        ),
      ),
    );
  }
}
