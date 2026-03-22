import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/dynamic_hypnosis_config.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/together_ai_service.dart';
import '../../services/elevenlabs_service.dart';
import '../../services/dynamic_hypnosis_storage_service.dart';
import '../../widgets/gradient_button.dart';
import '../dashboard/main_navigation_screen.dart';

class PreExperimentReviewScreen extends StatefulWidget {
  final String gender;
  final Map<String, dynamic> swashResponses;
  final Map<String, dynamic> psqiResponses;
  final Map<String, dynamic>? personalizedConfig;

  const PreExperimentReviewScreen({
    super.key,
    required this.gender,
    required this.swashResponses,
    required this.psqiResponses,
    this.personalizedConfig,
  });

  @override
  State<PreExperimentReviewScreen> createState() => _PreExperimentReviewScreenState();
}

class _PreExperimentReviewScreenState extends State<PreExperimentReviewScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _togetherAIService = TogetherAIService();
  final _elevenLabsService = ElevenLabsService();
  final _storageService = DynamicHypnosisStorageService();
  
  bool _isSubmitting = false;
  bool _isGenerating = false;
  String _generationStatus = '';

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = _authService.currentUserId;
      print('DEBUG: userId = $userId');
      if (userId == null) throw Exception('User not logged in');
      
      // Create participant with randomized conditions
      var participant = await _databaseService.getParticipantByUserId(userId);
      print('DEBUG: existing participant = ${participant?.id}');
      participant ??= await _databaseService.createParticipant(userId);
      print('DEBUG: participant id = ${participant.id}');
      
      print('DEBUG: swashResponses = ${widget.swashResponses}');
      print('DEBUG: psqiResponses = ${widget.psqiResponses}');
      print('DEBUG: personalizedConfig = ${widget.personalizedConfig}');
      
      // Save responses to database
      await _databaseService.savePreExperimentResponses(
        participantId: participant.id,
        gender: widget.gender,
        swashResponses: widget.swashResponses,
        psqiResponses: widget.psqiResponses,
        personalizedConfig: widget.personalizedConfig,
      );

      // Generate personalized hypnosis if config exists
      if (widget.personalizedConfig != null) {
        setState(() {
          _isGenerating = true;
          _generationStatus = 'Preparing AI generation...';
        });

        await _generatePersonalizedHypnosis(participant.id);
      }

      if (mounted) {
        // Navigate to main navigation screen and clear all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
        );
      }
    } catch (e, stack) {
      print('ERROR saving responses: $e');
      print('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving responses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _generatePersonalizedHypnosis(String participantId) async {
    final config = DynamicHypnosisConfig(
      characterChoice: widget.personalizedConfig!['character_choice'],
      goal: widget.personalizedConfig!['goal'],
      voiceId: widget.personalizedConfig!['voice_id'],
      voiceName: widget.personalizedConfig!['voice_name'],
    );

    // Generate script directly - skip local cache since we save to Supabase
    setState(() => _generationStatus = 'Generating script...');
    
    final scriptText = await _togetherAIService.generateHypnosisScript(
      characterChoice: config.characterChoice,
      goal: config.goal,
      genre: widget.personalizedConfig!['genre'],
      characterCategory: widget.personalizedConfig!['character_category'],
    );
    
    // DEBUG: Print script to console for review
    print('========== GENERATED SCRIPT ==========');
    print('Genre: ${widget.personalizedConfig!['genre']}');
    print('Character: ${config.characterChoice}');
    print('Script length: ${scriptText.length} characters');
    print(scriptText);
    print('========================================');

    // Convert to audio - save directly to Supabase
    if (!mounted) return;
    setState(() => _generationStatus = 'Converting to audio...');
    
    // Get audio bytes directly and save to Supabase (skip local file)
    final audioBytes = await _elevenLabsService.textToSpeech(
      text: scriptText,
      voiceId: config.voiceId,
    );

    // Save to Supabase with audio
    if (!mounted) return;
    setState(() => _generationStatus = 'Saving to cloud...');
    
    await _storageService.saveToSupabaseDirectly(
      config: config,
      participantId: participantId,
      scriptText: scriptText,
      audioBytes: audioBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Review & Submit'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review & Submit',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please review your responses before submitting',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Step 5 of 5',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 32),

                // Completion message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accentGreen.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Questionnaires Complete',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You\'ve completed all pre-experiment questionnaires. Click "Submit" to continue to the study.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

            // Summary cards
            _buildSummaryCard(
              title: 'Demographics',
              content: 'Gender: ${_formatGender(widget.gender)}',
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: 'Hypnotic Suggestibility',
              content: 'Completed ✓',
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: 'PSQI',
              content: 'Sleep quality assessment completed ✓',
            ),
            const SizedBox(height: 12),
            if (widget.personalizedConfig != null)
              _buildSummaryCard(
                title: 'Personalized Hypnosis',
                content: 'Genre: ${widget.personalizedConfig!['genre']}\nCharacter: ${widget.personalizedConfig!['character_choice']}\nGoal: ${widget.personalizedConfig!['goal']}\nVoice: ${widget.personalizedConfig!['voice_name']}',
              ),

            const SizedBox(height: 32),

            // Confirmation note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                ),
              ),
              child: Text(
                'By submitting, you confirm that all information provided is accurate to the best of your knowledge.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primaryPurple.withOpacity(0.5),
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
      
      // Generation overlay
      if (_isGenerating)
        Container(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  'Setting Up',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    _generationStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Please do not close the app',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSummaryCard({
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatGender(String gender) {
    switch (gender) {
      case 'woman':
        return 'Woman';
      case 'man':
        return 'Man';
      default:
        return gender;
    }
  }
}
