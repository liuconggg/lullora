import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';
import '../../models/dynamic_hypnosis_config.dart';
import '../../models/voice_option.dart';
import '../../services/together_ai_service.dart';
import '../../services/elevenlabs_service.dart';
import '../../services/dynamic_hypnosis_storage_service.dart';
import '../../widgets/safety_warning_card.dart';
import 'personalized_hypnosis_screen.dart';

class DynamicHypnosisSetupScreen extends StatefulWidget {
  final String? sessionId; // Optional - created later if null
  final String participantId;

  const DynamicHypnosisSetupScreen({
    super.key,
    this.sessionId,
    required this.participantId,
  });

  @override
  State<DynamicHypnosisSetupScreen> createState() => _DynamicHypnosisSetupScreenState();
}

class _DynamicHypnosisSetupScreenState extends State<DynamicHypnosisSetupScreen> {
  final _characterController = TextEditingController();
  final _goalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _togetherAIService = TogetherAIService();
  final _elevenLabsService = ElevenLabsService();
  final _storageService = DynamicHypnosisStorageService();
  
  List<VoiceOption> _voices = [];
  VoiceOption? _selectedVoice;
  bool _isLoadingVoices = true;
  bool _isGenerating = false;
  String _generationStatus = '';
  
  // Voice preview
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPreviewPlaying = false;
  String? _previewingVoiceId;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  @override
  void dispose() {
    _characterController.dispose();
    _goalController.dispose();
    _previewPlayer.dispose();
    super.dispose();
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

  Future<void> _loadVoices() async {
    try {
      final voices = await _elevenLabsService.getAvailableVoices(filterForHypnotherapy: true);
      setState(() {
        _voices = voices;
        _isLoadingVoices = false;
        if (voices.isNotEmpty) {
          _selectedVoice = voices.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingVoices = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load voices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateHypnosisSession() async {
    if (!_formKey.currentState!.validate() || _selectedVoice == null) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationStatus = 'Preparing AI generation... (0%)';
    });

    try {
      final config = DynamicHypnosisConfig(
        characterChoice: _characterController.text.trim(),
        goal: _goalController.text.trim(),
        voiceId: _selectedVoice!.voiceId,
        voiceName: _selectedVoice!.name,
      );

      final scriptExists = await _storageService.scriptExists(config);
      final audioExists = await _storageService.audioExists(config);

      String audioPath;
      String scriptText;
      
      if (scriptExists && audioExists) {
        setState(() {
          _generationStatus = 'Loading from cache... (100%)';
        });
        audioPath = await _storageService.getAudioPath(config);
        scriptText = await _storageService.loadScript(config);
      } else {
        setState(() {
          _generationStatus = 'Generating script with AI...';
        });

        scriptText = await _togetherAIService.generateHypnosisScript(
          characterChoice: config.characterChoice,
          goal: config.goal,
          genre: 'Fantasy', // Default genre for study sessions
        );

        await _storageService.saveScript(config, scriptText);

        if (!mounted) return;
        setState(() {
          _generationStatus = 'Converting to speech (this may take 30-60 seconds)...';
        });
        
        audioPath = await _storageService.getAudioPath(config);
        
        await _elevenLabsService.textToSpeechToFile(
          text: scriptText,
          voiceId: config.voiceId,
          outputPath: audioPath,
        );
        
        if (!mounted) return;
        setState(() {
          _generationStatus = 'Complete! Saving to cloud...';
        });
        
        // Save to Supabase now that bucket exists
        await _storageService.saveToSupabase(
          config: config,
          participantId: widget.participantId,
          sessionId: widget.sessionId,
          scriptText: scriptText,
          localAudioPath: audioPath,
        );
      }

      if (mounted) {
        // Use push (not pushReplacement) so user can go back to this screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PersonalizedHypnosisScreen(
              sessionId: widget.sessionId, // Can be null - screen will create if needed
              audioFilePath: audioPath,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationStatus = '';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate session: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isGenerating,
      onPopInvoked: (didPop) async {
        if (!didPop && _isGenerating) {
          // Show warning that generation is in progress
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Generation in Progress'),
              content: const Text(
                'Your hypnosis session is still being generated. '
                'If you go back now, the process will continue in the background '
                'and you can return to the home screen.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
          
          if (shouldExit == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          title: const Text('Personalized Hypnosis Setup'),
          backgroundColor: Colors.transparent,
        ),
        body: _isGenerating ? _buildGeneratingView() : _buildSetupForm(),
      ),
    );
  }

  Widget _buildGeneratingView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(height: 32),
            Text(
              _generationStatus,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This process may take 30-60 seconds',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize Your Session',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a unique hypnosis experience with AI',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            
            // Character Input
            _buildCharacterInput(),
            const SizedBox(height: 24),
            
            // Goal Input
            _buildGoalInput(),
            const SizedBox(height: 24),
            
            // Voice Selector
            _buildVoiceSelector(),
            const SizedBox(height: 32),
            
            // Safety warning
            const SafetyWarningCard(),
            const SizedBox(height: 24),
            
            // Generate Button
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Character Style',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _characterController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g., Yoda, Morgan Freeman, David Attenborough',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a character';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'The script will be written in this character\'s style and tone',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep Goal',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _goalController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., deep relaxation and restful sleep, anxiety relief, stress management',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your sleep goal';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVoiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_isLoadingVoices)
          Container(
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
          )
        else if (_voices.isEmpty)
          Container(
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
          )
        else
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
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a voice';
                    }
                    return null;
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
              : 'The AI will use this voice to narrate your hypnosis session',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _voices.isEmpty ? null : _generateHypnosisSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Generate Hypnosis Session',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
