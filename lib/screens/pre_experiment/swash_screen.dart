import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/gradient_button.dart';
import 'psqi_screen.dart';

/// Hypnotic Suggestibility Questionnaire Screen
/// A simple 10-question Yes/No questionnaire to assess hypnotic suggestibility
class SwashScreen extends StatefulWidget {
  final String gender;
  final String? genderSelfDescribe;

  const SwashScreen({super.key, required this.gender, this.genderSelfDescribe});

  @override
  State<SwashScreen> createState() => _SwashScreenState();
}

class _SwashScreenState extends State<SwashScreen> {
  // Questions for the hypnotic suggestibility questionnaire
  final List<String> _questions = [
    'Do you have many vivid memories from your early childhood?',
    'Do you tend to lose yourself in movies, books, or TV shows?',
    'Do you tend to know what people are going to say before they say it?',
    'Do powerful visual images ever trigger a physical sensation in you? For example, do you feel thirsty during any desert scenes?',
    'Have you ever zoned out while going somewhere and wondered how you\'d gotten there?',
    'Do you sometimes think in images rather than in words?',
    'Do you ever sense when someone has entered a room, even before seeing him?',
    'Do you like to look at cloud shapes?',
    'Do smells evoke powerful memories for you?',
    'Have you ever been deeply moved by a sunset?',
  ];

  // Answers: null = unanswered, true = yes, false = no
  final List<bool?> _answers = List.filled(10, null);

  int get _score => _answers.where((a) => a == true).length;
  
  bool get _allAnswered => _answers.every((a) => a != null);

  String get _resultCategory {
    if (_score <= 2) return 'low';
    if (_score <= 7) return 'medium';
    return 'high';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Hypnotic Suggestibility'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _buildQuestionnaire(),
      ),
    );
  }

  Widget _buildQuestionnaire() {
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Answer all questions',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                  ),
                  Text(
                    '${_answers.where((a) => a != null).length}/10',
                    style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _answers.where((a) => a != null).length / 10,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        
        // Questions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _questions.length,
            itemBuilder: (context, index) => _buildQuestionCard(index),
          ),
        ),
        
        // Submit button - goes directly to PSQI without showing results
        Padding(
          padding: const EdgeInsets.all(24),
          child: Opacity(
            opacity: _allAnswered ? 1.0 : 0.5,
            child: GradientButton(
              text: 'Next',
              icon: Icons.arrow_forward,
              onPressed: () {
                if (_allAnswered) {
                  // Skip results page - go directly to PSQI
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PsqiScreen(
                      gender: widget.gender,
                      swashResponses: {
                        'score': _score,
                        'category': _resultCategory,
                        'answers': _answers.map((a) => a == true ? 'yes' : 'no').toList(),
                      },
                    ),
                  ));
                }
              },
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index) {
    final answer = _answers[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: answer != null 
              ? AppTheme.primaryPurple.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: answer != null 
                      ? AppTheme.primaryPurple 
                      : Colors.white.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: answer != null ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _questions[index],
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(index, true, 'Yes'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnswerButton(index, false, 'No'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int questionIndex, bool isYes, String label) {
    final isSelected = _answers[questionIndex] == isYes;
    
    return GestureDetector(
      onTap: () => setState(() => _answers[questionIndex] = isYes),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isYes ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2))
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isYes ? Colors.green : Colors.red)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: isYes ? Colors.green : Colors.red,
                ),
              if (isSelected) const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? (isYes ? Colors.green : Colors.red) 
                      : Colors.white.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
