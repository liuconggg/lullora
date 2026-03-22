import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/questionnaire_progress_bar.dart';
import 'swash_screen.dart';

class DemographicsScreen extends StatefulWidget {
  const DemographicsScreen({super.key});

  @override
  State<DemographicsScreen> createState() => _DemographicsScreenState();
}

class _DemographicsScreenState extends State<DemographicsScreen> {
  String? _selectedGender;
  final _selfDescribeController = TextEditingController();
  bool _showSelfDescribe = false;

  @override
  void dispose() {
    _selfDescribeController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwashScreen(
          gender: _selectedGender!,
          genderSelfDescribe: _showSelfDescribe ? _selfDescribeController.text : null,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Pre-Experiment Questionnaire'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demographics',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Basic demographic information',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const QuestionnaireProgressBar(currentStep: 1, totalSteps: 4),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What is your gender?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),


                  ...['Woman', 'Man', 'Non-binary', 'Prefer to self-describe', 'Prefer not to disclose'].map((gender) {
                    // Map display names to database values
                    final dbValue = _getGenderValue(gender);
                    
                    return RadioListTile<String>(
                      title: Text(
                        gender,
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: dbValue,
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                          _showSelfDescribe = value == 'self_describe';
                        });
                      },
                      activeColor: AppTheme.primaryPurple,
                    );
                  }),

                  // Self-describe text field
                  if (_showSelfDescribe) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _selfDescribeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Please describe your gender...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                ],
              ),
            ),

            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    text: 'Next',
                    icon: Icons.arrow_forward,
                    onPressed: _handleNext,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Maps display gender values to database constraint values
  String _getGenderValue(String displayValue) {
    switch (displayValue) {
      case 'Woman':
        return 'woman';
      case 'Man':
        return 'man';
      case 'Non-binary':
        return 'non_binary';
      case 'Prefer to self-describe':
        return 'self_describe';
      case 'Prefer not to disclose':
        return 'prefer_not_to_disclose';
      default:
        return displayValue.toLowerCase();
    }
  }
}
