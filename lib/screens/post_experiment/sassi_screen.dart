import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';
import '../../widgets/gradient_button.dart';
import '../dashboard/home_screen.dart';
import '../dashboard/main_navigation_screen.dart';

class SassiScreen extends StatefulWidget {
  final String participantId;

  const SassiScreen({
    super.key,
    required this.participantId,
  });

  @override
  State<SassiScreen> createState() => _SassiScreenState();
}

class _SassiScreenState extends State<SassiScreen> {
  final _databaseService = DatabaseService();
  final _feedbackController = TextEditingController();
  final Map<String, int> _responses = {};
  bool _isLoading = false;

  // SASSI questions organized by category - Refined for Sleep Hypnosis Context
  final List<Map<String, dynamic>> _questions = [
    {'id': 'q1', 'category': 'System Response Accuracy', 'text': 'The system is accurate.'},
    {'id': 'q2', 'category': 'System Response Accuracy', 'text': 'The system didn\'t always do what I expected.'},
    {'id': 'q3', 'category': 'System Response Accuracy', 'text': 'The system is dependable.'},
    {'id': 'q4', 'category': 'Likeability', 'text': 'The system is useful.'},
    {'id': 'q5', 'category': 'Likeability', 'text': 'The system is pleasant.'},
    {'id': 'q6', 'category': 'Likeability', 'text': 'I enjoyed using the system.'},
    {'id': 'q7', 'category': 'Likeability', 'text': 'I would use this system.'},
    {'id': 'q8', 'category': 'Cognitive Demand', 'text': 'I felt calm using the system.'},
    {'id': 'q9', 'category': 'Cognitive Demand', 'text': 'The system is easy to use.'},
    {'id': 'q10', 'category': 'Annoyance', 'text': 'The system is irritating.'},
  ];

  Future<void> _handleSubmit() async {
    if (_responses.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your feedback')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _databaseService.savePostExperimentResponses(
        participantId: widget.participantId,
        sassiResponses: _responses,
        openFeedback: _feedbackController.text.trim(),
      );

      await _databaseService.completeStudy(widget.participantId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study completed! Check your sessions.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to Sessions tab (index 1) after completing study
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialTabIndex: 1)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Post-Experiment Questionnaire'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  Text(
                    'System Usability (SASSI)',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please rate each statement about the Lullora sleep system',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Questions
                  ..._questions.map((q) => _buildQuestion(q)),

                  const SizedBox(height: 32),

                  // Open feedback
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
                          'Additional Feedback *',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _feedbackController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Please share your thoughts and feedback about your experience... (required)',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  GradientButton(
                    text: 'Complete Study',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
            q['text'],
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Scale instruction
          Text(
            'Rate from 1 (Strongly Disagree) to 7 (Strongly Agree)',
            style: TextStyle(
              color: AppTheme.primaryPurple.withOpacity(0.8),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final value = index + 1;
              final isSelected = _responses[q['id']] == value;
              
              return GestureDetector(
                onTap: () => setState(() => _responses[q['id']] = value),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryPurple 
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryPurple 
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$value',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '1 = Strongly Disagree',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '7 = Strongly Agree',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
