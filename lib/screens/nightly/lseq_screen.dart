import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';
import '../../services/sleep_session_state_service.dart';
import '../../widgets/gradient_button.dart';
import '../dashboard/main_navigation_screen.dart';
import '../post_experiment/sassi_screen.dart';

class LseqScreen extends StatefulWidget {
  final String sessionId;

  const LseqScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<LseqScreen> createState() => _LseqScreenState();
}

class _LseqScreenState extends State<LseqScreen> {
  final _databaseService = DatabaseService();
  final Map<String, double> _responses = {};
  bool _isLoading = false;

  // LSEQ Structure organized by category
  final Map<String, dynamic> _lseqStructure = {
    'GTS': {
      'category_name': 'Getting to Sleep',
      'instruction': 'How would you describe the way you currently fall asleep in comparison to usual?',
      'items': [
        {'id': 1, 'left_anchor': 'More difficult than usual', 'right_anchor': 'Easier than usual'},
        {'id': 2, 'left_anchor': 'Slower than usual', 'right_anchor': 'More quickly than usual'},
        {'id': 3, 'left_anchor': 'I feel less sleepy than usual', 'right_anchor': 'More sleepy than usual'},
      ]
    },
    'QOS': {
      'category_name': 'Quality of Sleep',
      'instruction': 'How would you describe the quality of your sleep compared to normal sleep?',
      'items': [
        {'id': 4, 'left_anchor': 'More restless than usual', 'right_anchor': 'Calmer than usual'},
        {'id': 5, 'left_anchor': 'With more wakeful periods than usual', 'right_anchor': 'With less wakeful periods than usual'},
      ]
    },
    'AFS': {
      'category_name': 'Awake Following Sleep',
      'instruction': 'How would you describe your awakening in comparison to usual?',
      'items': [
        {'id': 6, 'left_anchor': 'More difficult than usual', 'right_anchor': 'Easier than usual'},
        {'id': 7, 'left_anchor': 'Requires a period of time longer than usual', 'right_anchor': 'Shorter than usual'},
      ]
    },
    'BFW': {
      'category_name': 'Behaviour Following Wakening',
      'items': [
        {'id': 8, 'question': 'How do you feel when you wake up?', 'left_anchor': 'Tired', 'right_anchor': 'Alert'},
        {'id': 9, 'question': 'How do you feel now?', 'left_anchor': 'Tired', 'right_anchor': 'Alert'},
        {'id': 10, 'question': 'How would you describe your balance and co-ordination upon awakening?', 'left_anchor': 'More disrupted than usual', 'right_anchor': 'Less disrupted than usual'},
      ]
    }
  };

  @override
  void initState() {
    super.initState();
    // Initialize all responses with default value of 50.0 (neutral position)
    // This allows users to submit without dragging if they accept the default
    _lseqStructure.forEach((key, category) {
      final items = category['items'] as List;
      for (final item in items) {
        final id = item['id'].toString();
        _responses[id] = 50.0;
      }
    });
  }

  int get _totalQuestions {
    int count = 0;
    _lseqStructure.forEach((key, category) {
      count += (category['items'] as List).length;
    });
    return count;
  }

  Future<void> _handleSubmit() async {
    if (_responses.length != _totalQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions before proceeding')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> responsesToSave = Map.from(_responses);

      await _databaseService.savePostSleepResponses(widget.sessionId, responsesToSave);

      final session = await _databaseService.getSessionById(widget.sessionId);

      if (session != null) {
        await _databaseService.updateParticipantNight(session.participantId, session.nightNumber + 1);

        final stateService = SleepSessionStateService();
        await stateService.markCompleted(widget.sessionId);

        if (session.nightNumber == 3) {
          await _databaseService.completeStudy(session.participantId);
        }
      }

      if (mounted) {
        final isNight3 = session?.nightNumber == 3;

        if (isNight3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All nights completed! Please complete the final questionnaire.'),
              backgroundColor: AppTheme.accentGreen,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => SassiScreen(participantId: session!.participantId)),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Night completed! Great job!'), backgroundColor: AppTheme.accentGreen),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: Text(
          'Post-Sleep Questionnaire',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Leeds Sleep Evaluation',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please rate your sleep experience using the sliders below.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Questions by category
              ..._lseqStructure.entries.map((entry) {
                final categoryData = entry.value as Map<String, dynamic>;
                final categoryName = categoryData['category_name'] as String;
                final instruction = categoryData['instruction'] as String?;
                final items = categoryData['items'] as List;

                return _buildCategorySection(
                  categoryName: categoryName,
                  instruction: instruction,
                  items: items,
                );
              }),

              const SizedBox(height: 24),

              // Submit Button
              GradientButton(
                text: 'Complete Questionnaire',
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String categoryName,
    String? instruction,
    required List items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            categoryName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryPurple,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Instruction (if exists)
        if (instruction != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              instruction,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],

        // Items
        ...items.map((item) => _buildQuestionCard(item: item)),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestionCard({required Map<String, dynamic> item}) {
    final id = item['id'].toString();
    final question = item['question'] as String?;
    final leftAnchor = item['left_anchor'] as String;
    final rightAnchor = item['right_anchor'] as String;
    final currentValue = _responses[id] ?? 50.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number + text (if individual question)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item['id']}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
              if (question != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Scale labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  leftAnchor,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  rightAnchor,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryPurple,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: AppTheme.primaryPurple,
              overlayColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: currentValue,
              min: 0,
              max: 100,
              onChanged: (value) {
                setState(() => _responses[id] = value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
