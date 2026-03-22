import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/condition.dart';
import '../../models/dynamic_hypnosis_config.dart';
import '../../services/database_service.dart';
import '../../services/dynamic_hypnosis_storage_service.dart';
import '../../widgets/gradient_button.dart';
import 'normal_sleep_screen.dart';
import 'fixed_hypnosis_screen.dart';
import 'personalized_hypnosis_screen.dart';

class SssScreen extends StatefulWidget {
  final String participantId;
  final int nightNumber;
  final Condition condition;

  const SssScreen({
    super.key,
    required this.participantId,
    required this.nightNumber,
    required this.condition,
  });

  @override
  State<SssScreen> createState() => _SssScreenState();
}

class _SssScreenState extends State<SssScreen> {
  final _databaseService = DatabaseService();
  final _storageService = DynamicHypnosisStorageService();
  int? _selectedLevel;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _sleepinessLevels = [
    {'level': 1, 'text': 'Feeling active, vital, alert, or wide awake'},
    {'level': 2, 'text': 'Functioning at high levels, but not at peak; able to concentrate'},
    {'level': 3, 'text': 'Awake, but relaxed; responsive but not fully alert'},
    {'level': 4, 'text': 'Somewhat foggy, let down'},
    {'level': 5, 'text': 'Foggy; losing interest in remaining awake; slowed down'},
    {'level': 6, 'text': 'Sleepy, woozy, fighting sleep; prefer to lie down'},
    {'level': 7, 'text': 'No longer fighting sleep, sleep onset soon; having dream-like thoughts'},
  ];

  Future<void> _handleSubmit() async {
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your sleepiness level')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create nightly session and save SSS immediately
    try {
      final session = await _databaseService.createNightlySession(
        participantId: widget.participantId,
        nightNumber: widget.nightNumber,
        condition: widget.condition,
      );

      await _databaseService.savePreSleepResponses(
        session.id,
        {'sleepiness_level': _selectedLevel!},
      );

      if (mounted) {
        // Navigate to appropriate condition screen with sessionId
        Widget conditionScreen;
        switch (widget.condition) {
          case Condition.control:
            conditionScreen = NormalSleepScreen(
              participantId: widget.participantId,
              nightNumber: widget.nightNumber,
              condition: widget.condition,
              sssLevel: _selectedLevel!,
              sessionId: session.id,
            );
            break;
          case Condition.fixed:
            conditionScreen = FixedHypnosisScreen(
              participantId: widget.participantId,
              nightNumber: widget.nightNumber,
              condition: widget.condition,
              sssLevel: _selectedLevel!,
              sessionId: session.id,
            );
            break;
          case Condition.personalized:
            // Load pre-generated audio from storage
            // Note: session_id in dynamic_hypnosis_sessions is linked via Asleep session ID
            // when sleep tracking completes (in SleepSessionStateService)
            final audioPath = await _loadPersonalizedAudio();
            conditionScreen = PersonalizedHypnosisScreen(
              sessionId: session.id,
              audioFilePath: audioPath,
            );
            break;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => conditionScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    }
  }

  /// Load the pre-generated personalized audio from Supabase
  Future<String?> _loadPersonalizedAudio() async {
    try {
      // Load from Supabase by participant
      final sessions = await _storageService.getAllForParticipant(widget.participantId);
      
      if (sessions.isNotEmpty) {
        final latestSession = sessions.first;
        
        // Check if audio exists locally
        final config = DynamicHypnosisConfig(
          characterChoice: latestSession.characterChoice,
          goal: latestSession.goal,
          voiceId: latestSession.voiceId,
          voiceName: latestSession.voiceName,
        );
        
        final localExists = await _storageService.audioExists(config);
        if (localExists) {
          return await _storageService.getAudioPath(config);
        }
        
        // Download from Supabase storage
        if (latestSession.audioStoragePath != null) {
          return await _storageService.downloadAudioFromStorage(
            storagePath: latestSession.audioStoragePath!,
            config: config,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading personalized audio: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Pre-Sleep Questionnaire'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stanford Sleepiness Scale',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How do you feel right now?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: _sleepinessLevels.map((item) {
                  return _buildSleepinessOption(
                    level: item['level'],
                    text: item['text'],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),
            GradientButton(
              text: 'Continue',
              onPressed: _handleSubmit,
              isLoading: _isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepinessOption({required int level, required String text}) {
    final isSelected = _selectedLevel == level;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryPurple.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryPurple 
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected 
                    ? AppTheme.primaryPurple 
                    : Colors.white.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
