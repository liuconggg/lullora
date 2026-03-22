import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/questionnaire_progress_bar.dart';
import 'pre_experiment_personalized_setup_screen.dart';

class PsqiScreen extends StatefulWidget {
  final String gender;
  final Map<String, dynamic> swashResponses;

  const PsqiScreen({
    super.key,
    required this.gender,
    required this.swashResponses,
  });

  @override
  State<PsqiScreen> createState() => _PsqiScreenState();
}

class _PsqiScreenState extends State<PsqiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minutesToFallAsleepController = TextEditingController();
  final _hoursOfSleepController = TextEditingController();
  final _otherReasonDescriptionController = TextEditingController();
  final _otherRestlessnessController = TextEditingController();

  // Q1 & Q3: Time selections
  TimeOfDay? _bedTime;
  TimeOfDay? _wakeTime;
  
  // Q5: Sleep disturbances (5a-5j)
  int? _cannotSleepWithin30Min;
  int? _wakeUpNightOrEarly;
  int? _getBathroom;
  int? _cannotBreathe;
  int? _coughSnore;
  int? _feelTooCold;
  int? _feelTooHot;
  int? _badDreams;
  int? _havePain;
  int? _otherReason;
  
  // Q6: Overall quality
  int? _overallQuality;
  
  // Q7: Medication
  int? _medicationUse;
  
  // Q8: Daytime dysfunction
  int? _troubleStayingAwake;
  
  // Q9: Enthusiasm
  int? _enthusiasmDifficulty;
  
  // Q10: Bed partner
  String? _bedPartnerStatus;
  int? _loudSnoring;
  int? _breathingPauses;
  int? _legTwitching;
  int? _disorientation;
  int? _otherRestlessness;

  @override
  void dispose() {
    _minutesToFallAsleepController.dispose();
    _hoursOfSleepController.dispose();
    _otherReasonDescriptionController.dispose();
    _otherRestlessnessController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bedTime == null || _wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required time fields')),
      );
      return;
    }

    if (mounted) {
      // Build nested structure matching database schema
      final psqiResponses = {
        'bed_time': '${_bedTime!.hour.toString().padLeft(2, '0')}:${_bedTime!.minute.toString().padLeft(2, '0')}',
        'sleep_latency_minutes': int.tryParse(_minutesToFallAsleepController.text) ?? 0,
        'wake_time': '${_wakeTime!.hour.toString().padLeft(2, '0')}:${_wakeTime!.minute.toString().padLeft(2, '0')}',
        'actual_sleep_hours': double.tryParse(_hoursOfSleepController.text) ?? 0,
        'disturbances': {
          'sleep_onset': _getFrequencyString(_cannotSleepWithin30Min),
          'night_waking': _getFrequencyString(_wakeUpNightOrEarly),
          'bathroom': _getFrequencyString(_getBathroom),
          'breathing': _getFrequencyString(_cannotBreathe),
          'cough_snore': _getFrequencyString(_coughSnore),
          'too_cold': _getFrequencyString(_feelTooCold),
          'too_hot': _getFrequencyString(_feelTooHot),
          'bad_dreams': _getFrequencyString(_badDreams),
          'pain': _getFrequencyString(_havePain),
          'other_description': _otherReasonDescriptionController.text,
          'other_frequency': _getFrequencyString(_otherReason),
        },
        'overall_quality': _getQualityString(_overallQuality),
        'medication_frequency': _getFrequencyString(_medicationUse),
        'daytime_dysfunction': _getFrequencyString(_troubleStayingAwake),
        'enthusiasm_problem': _getEnthusiasmString(_enthusiasmDifficulty),
        'bed_partner': {
          'status': _bedPartnerStatus ?? '',
          'snoring_frequency': _getFrequencyString(_loudSnoring),
          'breathing_pauses': _getFrequencyString(_breathingPauses),
          'leg_movement': _getFrequencyString(_legTwitching),
          'disorientation': _getFrequencyString(_disorientation),
          'other_restlessness': _otherRestlessnessController.text,
        },
      };

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreExperimentPersonalizedSetupScreen(
            gender: widget.gender,
            swashResponses: widget.swashResponses,
            psqiResponses: psqiResponses,
          ),
        ),
      );
    }
  }

  String _getFrequencyString(int? value) {
    if (value == null) return '';
    switch (value) {
      case 0:
        return 'not_during_past_month';
      case 1:
        return 'less_than_once_week';
      case 2:
        return 'once_or_twice_week';
      case 3:
        return 'three_or_more_times_week';
      default:
        return '';
    }
  }

  String _getQualityString(int? value) {
    if (value == null) return '';
    switch (value) {
      case 0:
        return 'very_good';
      case 1:
        return 'fairly_good';
      case 2:
        return 'fairly_bad';
      case 3:
        return 'very_bad';
      default:
        return '';
    }
  }

  String _getEnthusiasmString(int? value) {
    if (value == null) return '';
    switch (value) {
      case 0:
        return 'no_problem';
      case 1:
        return 'slight_problem';
      case 2:
        return 'somewhat_problem';
      case 3:
        return 'very_big_problem';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('PSQI Questionnaire'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pittsburgh Sleep Quality Index',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The following questions relate to your usual sleep habits during the past month only.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const QuestionnaireProgressBar(currentStep: 3, totalSteps: 4),
              const SizedBox(height: 32),

              // Q1: Bed time
              _buildQuestionCard(
                questionNumber: '1',
                question: 'During the past month, what time have you usually gone to bed at night?',
                required: true,
                child: _buildTimeField(
                  label: 'BED TIME',
                  value: _bedTime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 22, minute: 0),
                    );
                    if (time != null) setState(() => _bedTime = time);
                  },
                ),
              ),

              // Q2: Sleep latency
              _buildQuestionCard(
                questionNumber: '2',
                question: 'During the past month, how long (in minutes) has it usually taken you to fall asleep each night?',
                required: true,
                child: TextFormField(
                  controller: _minutesToFallAsleepController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('NUMBER OF MINUTES'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),

              // Q3: Wake time
              _buildQuestionCard(
                questionNumber: '3',
                question: 'During the past month, what time have you usually gotten up in the morning?',
                required: true,
                child: _buildTimeField(
                  label: 'GETTING UP TIME',
                  value: _wakeTime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                    );
                    if (time != null) setState(() => _wakeTime = time);
                  },
                ),
              ),

              // Q4: Hours of sleep
              _buildQuestionCard(
                questionNumber: '4',
                question: 'During the past month, how many hours of actual sleep did you get at night? (This may be different than the number of hours you spent in bed.)',
                required: true,
                child: TextFormField(
                  controller: _hoursOfSleepController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('HOURS OF SLEEP PER NIGHT'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),

              const SizedBox(height: 24),

              // Q5: Sleep Disturbances Section Header
              Text(
                '5. During the past month, how often have you had trouble sleeping because you...',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Q5a: Cannot sleep within 30 minutes
              _buildDisturbanceQuestion(
                label: 'a)',
                question: 'Cannot get to sleep within 30 minutes',
                selectedValue: _cannotSleepWithin30Min,
                onChanged: (value) => setState(() => _cannotSleepWithin30Min = value),
              ),

              // Q5b: Wake up in middle of night
              _buildDisturbanceQuestion(
                label: 'b)',
                question: 'Wake up in the middle of the night or early morning',
                selectedValue: _wakeUpNightOrEarly,
                onChanged: (value) => setState(() => _wakeUpNightOrEarly = value),
              ),

              // Q5c: Bathroom
              _buildDisturbanceQuestion(
                label: 'c)',
                question: 'Have to get up to use the bathroom',
                selectedValue: _getBathroom,
                onChanged: (value) => setState(() => _getBathroom = value),
              ),

              // Q5d: Breathing
              _buildDisturbanceQuestion(
                label: 'd)',
                question: 'Cannot breathe comfortably',
                selectedValue: _cannotBreathe,
                onChanged: (value) => setState(() => _cannotBreathe = value),
              ),

              // Q5e: Cough or snore
              _buildDisturbanceQuestion(
                label: 'e)',
                question: 'Cough or snore loudly',
                selectedValue: _coughSnore,
                onChanged: (value) => setState(() => _coughSnore = value),
              ),

              // Q5f: Too cold
              _buildDisturbanceQuestion(
                label: 'f)',
                question: 'Feel too cold',
                selectedValue: _feelTooCold,
                onChanged: (value) => setState(() => _feelTooCold = value),
              ),

              // Q5g: Too hot
              _buildDisturbanceQuestion(
                label: 'g)',
                question: 'Feel too hot',
                selectedValue: _feelTooHot,
                onChanged: (value) => setState(() => _feelTooHot = value),
              ),

              // Q5h: Bad dreams
              _buildDisturbanceQuestion(
                label: 'h)',
                question: 'Had bad dreams',
                selectedValue: _badDreams,
                onChanged: (value) => setState(() => _badDreams = value),
              ),

              // Q5i: Pain
              _buildDisturbanceQuestion(
                label: 'i)',
                question: 'Have pain',
                selectedValue: _havePain,
                onChanged: (value) => setState(() => _havePain = value),
              ),

              // Q5j: Other reason
              _buildQuestionCard(
                questionNumber: 'j)',
                question: 'Other reason(s), please describe',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _otherReasonDescriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Describe other reason (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'How often during the past month have you had trouble sleeping because of this?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFrequencyOptions(
                      selectedValue: _otherReason,
                      onChanged: (value) => setState(() => _otherReason = value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Q6: Overall sleep quality
              _buildQuestionCard(
                questionNumber: '6',
                question: 'During the past month, how would you rate your sleep quality overall?',
                required: true,
                child: _buildQualityOptions(
                  selectedValue: _overallQuality,
                  onChanged: (value) => setState(() => _overallQuality = value),
                ),
              ),

              // Q7: Medication
              _buildQuestionCard(
                questionNumber: '7',
                question: 'During the past month, how often have you taken medicine to help you sleep (prescribed or "over the counter")?',
                required: true,
                child: _buildFrequencyOptions(
                  selectedValue: _medicationUse,
                  onChanged: (value) => setState(() => _medicationUse = value),
                ),
              ),

              // Q8: Staying awake
              _buildQuestionCard(
                questionNumber: '8',
                question: 'During the past month, how often have you had trouble staying awake while driving, eating meals, or engaging in social activity?',
                required: true,
                child: _buildFrequencyOptions(
                  selectedValue: _troubleStayingAwake,
                  onChanged: (value) => setState(() => _troubleStayingAwake = value),
                ),
              ),

              // Q9: Enthusiasm
              _buildQuestionCard(
                questionNumber: '9',
                question: 'During the past month, how much of a problem has it been for you to keep up enough enthusiasm to get things done?',
                required: true,
                child: _buildEnthusiasmOptions(
                  selectedValue: _enthusiasmDifficulty,
                  onChanged: (value) => setState(() => _enthusiasmDifficulty = value),
                ),
              ),

              // Q10: Bed partner
              _buildQuestionCard(
                questionNumber: '10',
                question: 'Do you have a bed partner or room mate?',
                required: true,
                child: Column(
                  children: [
                    ...[
                      'no_bed_partner',
                      'partner_other_room',
                      'partner_same_room_different_bed',
                      'partner_same_bed',
                    ].asMap().entries.map((entry) {
                      final labels = [
                        'No bed partner or room mate',
                        'Partner/room mate in other room',
                        'Partner in same room, but not same bed',
                        'Partner in same bed',
                      ];
                      return RadioListTile<String>(
                        title: Text(
                          labels[entry.key],
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: entry.value,
                        groupValue: _bedPartnerStatus,
                        onChanged: (value) => setState(() => _bedPartnerStatus = value),
                        activeColor: AppTheme.primaryPurple,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                    if (_bedPartnerStatus != null && _bedPartnerStatus != 'no_bed_partner') ...[
                      const SizedBox(height: 16),
                      Text(
                        'If you have a room mate or bed partner, ask him/her how often in the past month you have had...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBedPartnerQuestion(
                        label: 'a)',
                        question: 'Loud snoring',
                        selectedValue: _loudSnoring,
                        onChanged: (value) => setState(() => _loudSnoring = value),
                      ),
                      _buildBedPartnerQuestion(
                        label: 'b)',
                        question: 'Long pauses between breaths while asleep',
                        selectedValue: _breathingPauses,
                        onChanged: (value) => setState(() => _breathingPauses = value),
                      ),
                      _buildBedPartnerQuestion(
                        label: 'c)',
                        question: 'Legs twitching or jerking while you sleep',
                        selectedValue: _legTwitching,
                        onChanged: (value) => setState(() => _legTwitching = value),
                      ),
                      _buildBedPartnerQuestion(
                        label: 'd)',
                        question: 'Episodes of disorientation or confusion during sleep',
                        selectedValue: _disorientation,
                        onChanged: (value) => setState(() => _disorientation = value),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'e) Other restlessness while you sleep; please describe',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _otherRestlessnessController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Describe other restlessness (optional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      _buildFrequencyOptions(
                        selectedValue: _otherRestlessness,
                        onChanged: (value) => setState(() => _otherRestlessness = value),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Navigation buttons
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required String questionNumber,
    required String question,
    required Widget child,
    bool required = false,
  }) {
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
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$questionNumber ',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                TextSpan(
                  text: question,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDisturbanceQuestion({
    required String label,
    required String question,
    required int? selectedValue,
    required Function(int) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                TextSpan(
                  text: question,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFrequencyOptions(
            selectedValue: selectedValue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBedPartnerQuestion({
    required String label,
    required String question,
    required int? selectedValue,
    required Function(int) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                TextSpan(
                  text: question,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildFrequencyOptions(
            selectedValue: selectedValue,
            onChanged: onChanged,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppTheme.primaryPurple),
            const SizedBox(width: 12),
            Text(
              value != null ? value.format(context) : label,
              style: TextStyle(
                color: value != null ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOptions({
    required int? selectedValue,
    required Function(int) onChanged,
    bool compact = false,
  }) {
    final options = [
      'Not during the past month',
      'Less than once a week',
      'Once or twice a week',
      'Three or more times a week',
    ];

    return Column(
      children: List.generate(options.length, (index) {
        return RadioListTile<int>(
          title: Text(
            options[index],
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 12 : 14,
            ),
          ),
          value: index,
          groupValue: selectedValue,
          onChanged: (value) => onChanged(value!),
          activeColor: AppTheme.primaryPurple,
          contentPadding: EdgeInsets.zero,
          dense: compact,
        );
      }),
    );
  }

  Widget _buildQualityOptions({
    required int? selectedValue,
    required Function(int) onChanged,
  }) {
    final options = [
      'Very good',
      'Fairly good',
      'Fairly bad',
      'Very bad',
    ];

    return Column(
      children: List.generate(options.length, (index) {
        return RadioListTile<int>(
          title: Text(
            options[index],
            style: const TextStyle(color: Colors.white),
          ),
          value: index,
          groupValue: selectedValue,
          onChanged: (value) => onChanged(value!),
          activeColor: AppTheme.primaryPurple,
          contentPadding: EdgeInsets.zero,
        );
      }),
    );
  }

  Widget _buildEnthusiasmOptions({
    required int? selectedValue,
    required Function(int) onChanged,
  }) {
    final options = [
      'No problem at all',
      'Only a very slight problem',
      'Somewhat of a problem',
      'A very big problem',
    ];

    return Column(
      children: List.generate(options.length, (index) {
        return RadioListTile<int>(
          title: Text(
            options[index],
            style: const TextStyle(color: Colors.white),
          ),
          value: index,
          groupValue: selectedValue,
          onChanged: (value) => onChanged(value!),
          activeColor: AppTheme.primaryPurple,
          contentPadding: EdgeInsets.zero,
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }
}
