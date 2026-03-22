import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/condition.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/safety_warning_card.dart';
import 'sss_screen.dart';
import 'dynamic_hypnosis_setup_screen.dart';

class NightSessionScreen extends StatelessWidget {
  final String participantId;
  final int nightNumber;
  final Condition condition;

  const NightSessionScreen({
    super.key,
    required this.participantId,
    required this.nightNumber,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Night $nightNumber'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(
              _getConditionIcon(),
              size: 80,
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                _getConditionDescription(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_android,
                    color: AppTheme.primaryPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Please find a comfortable place to sleep. Place your device at arm\'s length and ensure the volume is audible.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Safety warning for audio sessions only
            if (condition != Condition.control) ...[
              const SizedBox(height: 16),
              const SafetyWarningCard(),
            ],
            const SizedBox(height: 40),
            GradientButton(
              text: 'Start Pre-Sleep Questionnaire',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SssScreen(
                      participantId: participantId,
                      nightNumber: nightNumber,
                      condition: condition,
                    ),
                  ),
                );
              },
              width: double.infinity,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  IconData _getConditionIcon() {
    switch (condition) {
      case Condition.control:
        return Icons.bedtime_outlined;
      case Condition.fixed:
        return Icons.headphones_outlined;
      case Condition.personalized:
        return Icons.psychology_outlined;
    }
  }



  String _getConditionDescription() {
    switch (condition) {
      case Condition.control:
        return 'Tonight, you will sleep normally without any audio intervention. The app will track your sleep through the night.';
      case Condition.fixed:
      case Condition.personalized:
        return 'You will listen to this audio designed to help you fall asleep.';
    }
  }
}
