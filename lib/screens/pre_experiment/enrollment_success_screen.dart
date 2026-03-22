import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/participant.dart';
import '../../models/condition.dart';
import 'demographics_screen.dart';

class EnrollmentSuccessScreen extends StatefulWidget {
  const EnrollmentSuccessScreen({super.key});

  @override
  State<EnrollmentSuccessScreen> createState() => _EnrollmentSuccessScreenState();
}

class _EnrollmentSuccessScreenState extends State<EnrollmentSuccessScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createParticipantAndShowConditions();
  }

  Future<void> _createParticipantAndShowConditions() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      // Check if participant already exists
      Participant? participant = await _databaseService.getParticipantByUserId(userId);
      
      // If not, create new participant with randomized conditions
      participant ??= await _databaseService.createParticipant(userId);
      
      setState(() {
        _isLoading = false;
      });

      // Navigate after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        // Check if user has completed pre-experiment questionnaires
        // If status is still 'pre_experiment', go to demographics
        // If status is 'in_progress', go to main navigation (they already completed pre-exp)
        if (participant.status == StudyStatus.preExperiment) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DemographicsScreen(),
            ),
          );
        } else {
          // Already completed pre-experiment, go to main navigation
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/main',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Success icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: AppTheme.accentGreen,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Successfully Enrolled!',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You\'ve been enrolled in the sleep study. We\'ll guide you through a few questionnaires to get started.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),


                        // Redirecting message
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Redirecting to pre-experiment questionnaires...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
