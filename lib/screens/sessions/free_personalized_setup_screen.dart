import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';
import '../../models/dynamic_hypnosis_config.dart';
import '../../models/voice_option.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/elevenlabs_service.dart';
import '../../services/together_ai_service.dart';
import '../../services/dynamic_hypnosis_storage_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/safety_warning_card.dart';
import 'free_play_screen.dart';

class FreePersonalizedSetupScreen extends StatefulWidget {
  const FreePersonalizedSetupScreen({super.key});

  @override
  State<FreePersonalizedSetupScreen> createState() => _FreePersonalizedSetupScreenState();
}

class _FreePersonalizedSetupScreenState extends State<FreePersonalizedSetupScreen> {
  final _characterController = TextEditingController();
  final _goalController = TextEditingController();
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _elevenLabsService = ElevenLabsService();
  final _togetherAIService = TogetherAIService();
  final _storageService = DynamicHypnosisStorageService();
  
  // Voice preview
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPreviewPlaying = false;
  String? _previewingVoiceId;
  
  List<VoiceOption> _voices = [];
  VoiceOption? _selectedVoice;
  String? _selectedCharacter;
  String? _selectedGoal;
  bool _isLoadingVoices = true;
  bool _isGenerating = false;
  String _generationStatus = '';
  String? _participantId;

  // Match the character options from pre-experiment
  final List<String> _characterOptions = [
    'Mickey Mouse',
    'Superman',
    'Pikachu',
    'Harry Potter',
    'Cinderella',
    'Other (custom)',
  ];

  // Match the goal options from pre-experiment
  final List<String> _goalOptions = [
    'Sleep 7-8 hours per night',
    'Fall asleep faster',
    'Reduce nighttime awakenings',
    'Improve sleep quality',
    'Maintain consistent sleep schedule',
    'Other (custom)',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _characterController.dispose();
    _goalController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final participant = await _databaseService.getParticipantByUserId(userId);
      if (participant != null) {
        _participantId = participant.id;
      }

      // Use same filter as pre-experiment
      final voices = await _elevenLabsService.getAvailableVoices(filterForHypnotherapy: true);
      if (mounted) {
        setState(() {
          _voices = voices;
          if (voices.isNotEmpty) {
            _selectedVoice = voices.first;
          }
          _isLoadingVoices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVoices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load voices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playVoicePreview(VoiceOption voice) async {
    if (voice.previewUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No preview available for this voice'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If already playing this voice, stop it
    if (_isPreviewPlaying && _previewingVoiceId == voice.voiceId) {
      await _previewPlayer.stop();
      setState(() {
        _isPreviewPlaying = false;
        _previewingVoiceId = null;
      });
      return;
    }

    // Stop any currently playing preview
    await _previewPlayer.stop();

    setState(() {
      _isPreviewPlaying = true;
      _previewingVoiceId = voice.voiceId;
    });

    try {
      await _previewPlayer.play(UrlSource(voice.previewUrl!));
      
      // Listen for completion
      _previewPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPreviewPlaying = false;
            _previewingVoiceId = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPreviewPlaying = false;
          _previewingVoiceId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGenerate() async {
    // Validate
    if (_selectedCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a character style')),
      );
      return;
    }
    if (_selectedCharacter == 'Other (custom)' && _characterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your custom character')),
      );
      return;
    }
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sleep goal')),
      );
      return;
    }
    if (_selectedGoal == 'Other (custom)' && _goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your custom goal')),
      );
      return;
    }
    if (_selectedVoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a voice')),
      );
      return;
    }
    if (_participantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    // Check customisation limit (backup validation)
    final sessionCount = await _storageService.getSessionCount(_participantId!);
    if (sessionCount >= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already used your free customisation'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final characterChoice = _selectedCharacter == 'Other (custom)'
        ? _characterController.text.trim()
        : _selectedCharacter!;
    final goalChoice = _selectedGoal == 'Other (custom)'
        ? _goalController.text.trim()
        : _selectedGoal!;

    final config = DynamicHypnosisConfig(
      characterChoice: characterChoice,
      goal: goalChoice,
      voiceId: _selectedVoice!.voiceId,
      voiceName: _selectedVoice!.name,
    );

    setState(() {
      _isGenerating = true;
      _generationStatus = 'Setting up the app...';
    });

    try {
      // Generate script
      final scriptText = await _togetherAIService.generateHypnosisScript(
        characterChoice: characterChoice,
        goal: goalChoice,
        genre: 'Fantasy', // Default genre for free play
      );

      if (!mounted) return;
      setState(() => _generationStatus = 'Almost there...');

      // Convert to audio
      final audioBytes = await _elevenLabsService.textToSpeech(
        text: scriptText,
        voiceId: _selectedVoice!.voiceId,
      );

      if (!mounted) return;

      // Save to Supabase
      final session = await _storageService.saveToSupabaseDirectly(
        config: config,
        participantId: _participantId!,
        scriptText: scriptText,
        audioBytes: audioBytes,
      );

      if (session == null) {
        throw Exception('Failed to save session');
      }

      if (!mounted) return;

      // Navigate to playback
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FreePlayScreen(
            participantId: _participantId!,
            isFixedAudio: false,
            audioStoragePath: session.audioStoragePath,
            sessionTitle: '$characterChoice - $goalChoice',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Create Personalized Session'),
        backgroundColor: Colors.transparent,
      ),
      body: _isGenerating
          ? _buildGeneratingOverlay()
          : _isLoadingVoices
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Choose Your Character'),
                      const SizedBox(height: 8),
                      Text(
                        'Select a character that will guide your hypnosis session',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCharacterSelection(),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle('Sleep Goal'),
                      const SizedBox(height: 8),
                      Text(
                        'What would you like to achieve?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGoalSelection(),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle('Voice'),
                      const SizedBox(height: 16),
                      _buildVoiceSelection(),
                      
                      const SizedBox(height: 32),
                      
                      // Safety warning before generating
                      const SafetyWarningCard(),
                      
                      const SizedBox(height: 24),
                      
                      GradientButton(
                        text: 'Generate & Play',
                        icon: Icons.play_arrow,
                        onPressed: _handleGenerate,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGeneratingOverlay() {
    return Container(
      color: AppTheme.darkBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _generationStatus,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few minutes...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCharacterSelection() {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _characterOptions.map((option) {
            final isSelected = _selectedCharacter == option;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCharacter = option;
                if (option != 'Other (custom)') {
                  _characterController.clear();
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryPurple : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryPurple : Colors.white.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedCharacter == 'Other (custom)') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _characterController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your custom character...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
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
    );
  }

  Widget _buildGoalSelection() {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _goalOptions.map((option) {
            final isSelected = _selectedGoal == option;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedGoal = option;
                if (option != 'Other (custom)') {
                  _goalController.clear();
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryPurple : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryPurple : Colors.white.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedGoal == 'Other (custom)') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _goalController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your custom sleep goal...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
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
    );
  }

  Widget _buildVoiceSelection() {
    if (_isLoadingVoices) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading voices...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    if (_voices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Text(
          'Failed to load voices. Please check your API key.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<VoiceOption>(
                value: _selectedVoice,
                dropdownColor: AppTheme.cardBackground,
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
                  ),
                ),
                items: _voices.map((voice) {
                  return DropdownMenuItem(
                    value: voice,
                    child: Text(
                      voice.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVoice = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // Preview button
            GestureDetector(
              onTap: _selectedVoice != null 
                  ? () => _playVoicePreview(_selectedVoice!)
                  : null,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _isPreviewPlaying && _previewingVoiceId == _selectedVoice?.voiceId
                      ? AppTheme.primaryPurple
                      : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedVoice != null 
                        ? AppTheme.primaryPurple.withOpacity(0.5)
                        : AppTheme.borderColor,
                  ),
                ),
                child: Icon(
                  _isPreviewPlaying && _previewingVoiceId == _selectedVoice?.voiceId
                      ? Icons.stop
                      : Icons.play_arrow,
                  color: _selectedVoice != null 
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedVoice != null 
              ? 'Tap the play button to preview this voice'
              : 'Select a voice for your personalized hypnosis session',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

