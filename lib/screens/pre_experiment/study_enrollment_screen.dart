import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/gradient_button.dart';
import 'enrollment_success_screen.dart';

class StudyEnrollmentScreen extends StatefulWidget {
  const StudyEnrollmentScreen({super.key});

  @override
  State<StudyEnrollmentScreen> createState() => _StudyEnrollmentScreenState();
}

class _StudyEnrollmentScreenState extends State<StudyEnrollmentScreen> {
  bool _consentChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Join Our Sleep Study',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us understand how hypnosis affects sleep quality',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Study Overview
              Text(
                'Study Overview',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This research study investigates the effectiveness of hypnosis sessions on sleep quality over three consecutive nights. You will experience three different conditions in a randomized order.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Important: Randomized Study Design
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryPurple, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Important: Randomized Study Design',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Each participant receives a unique random order of the three conditions. This means your night 1 condition may be different from another participant\'s night 1.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For example: You might get "Fixed Hypnosis" on night 1, while another participant might get "Normal Sleep" on their night 1. This randomization is crucial for valid scientific results.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // What to Expect
              Text(
                'What to Expect',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildExpectationItem(
                icon: Icons.nightlight_round,
                title: 'Three Nights',
                description: 'Participate for three consecutive nights in your own home',
              ),
              _buildExpectationItem(
                icon: Icons.shuffle,
                title: 'Three Conditions (in random order)',
                bullets: [
                  'Normal sleep (control)',
                  'Fixed hypnosis session (13 min pre-recorded audio)',
                  'Personalized hypnosis session (13 min AI-generated audio)',
                ],
              ),
              _buildExpectationItem(
                icon: Icons.assignment,
                title: 'Quick Surveys',
                description: '5-10 minutes before bed and after waking each night',
              ),
              _buildExpectationItem(
                icon: Icons.bedtime,
                title: 'Sleep Tracking',
                description: 'Automatic sleep monitoring throughout the night',
              ),

              const SizedBox(height: 32),

              // Time Commitment
              Text(
                'Time Commitment',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeItem('Pre-study questionnaire: ~10 minutes'),
              _buildTimeItem('Each night before bed: ~5 minutes'),
              _buildTimeItem('Each morning: ~5 minutes'),
              _buildTimeItem('Post-study questionnaire: ~5 minutes'),

              const SizedBox(height: 32),

              // Informed Consent
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informed Consent',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildConsentItem('Your participation is completely voluntary'),
                    _buildConsentItem('You can withdraw from the study at any time'),
                    _buildConsentItem('All data will be kept confidential and anonymized'),
                    _buildConsentItem('Your data will only be used for research purposes'),
                    _buildConsentItem('You can request to have your data deleted at any time'),
                    const SizedBox(height: 16),
                    
                    // Consent checkbox
                    InkWell(
                      onTap: () => setState(() => _consentChecked = !_consentChecked),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _consentChecked,
                            onChanged: (value) => setState(() => _consentChecked = value ?? false),
                            activeColor: AppTheme.primaryPurple,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'I have read and understood the study information above. I consent to participate in this research study and understand that I can withdraw at any time.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Not Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: !_consentChecked
                          ? null
                          : () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const EnrollmentSuccessScreen(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Start Questionnaires'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.primaryPurple.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpectationItem({
    required IconData icon,
    required String title,
    String? description,
    List<String>? bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                if (bullets != null) ...[
                  const SizedBox(height: 8),
                  ...bullets.map((bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $bullet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

