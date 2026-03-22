import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';
import '../../models/voice_option.dart';
import '../../services/elevenlabs_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/questionnaire_progress_bar.dart';
import 'review_submit_screen.dart';

/// Screen for setting up personalized hypnosis preferences during pre-experiment
/// This saves the configuration for later use during the study
class PreExperimentPersonalizedSetupScreen extends StatefulWidget {
  final String gender;
  final Map<String, dynamic> swashResponses;
  final Map<String, dynamic> psqiResponses;

  const PreExperimentPersonalizedSetupScreen({
    super.key,
    required this.gender,
    required this.swashResponses,
    required this.psqiResponses,
  });

  @override
  State<PreExperimentPersonalizedSetupScreen> createState() => _PreExperimentPersonalizedSetupScreenState();
}

class _PreExperimentPersonalizedSetupScreenState extends State<PreExperimentPersonalizedSetupScreen> {
  final _characterController = TextEditingController();
  final _goalController = TextEditingController();
  final _genreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _elevenLabsService = ElevenLabsService();
  
  List<VoiceOption> _voices = [];
  VoiceOption? _selectedVoice;
  bool _isLoadingVoices = true;
  
  // Voice preview
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPreviewPlaying = false;
  String? _previewingVoiceId;
  
  // ========== GENRE OPTIONS ==========
  final List<Map<String, dynamic>> _genreOptions = [
    {'name': 'Fantasy', 'icon': Icons.auto_awesome, 'description': 'Magical realms & mystical journeys'},
    {'name': 'Sci-Fi', 'icon': Icons.rocket_launch, 'description': 'Futuristic & space adventures'},
    {'name': 'Adventure', 'icon': Icons.explore, 'description': 'Epic quests & exploration'},
    {'name': 'Romance', 'icon': Icons.favorite, 'description': 'Warm, comforting narratives'},
    {'name': 'Nature', 'icon': Icons.park, 'description': 'Peaceful forests & oceans'},
    {'name': 'Mystery', 'icon': Icons.psychology, 'description': 'Intriguing & thought-provoking'},
    {'name': 'Fairy Tale', 'icon': Icons.castle, 'description': 'Classic storybook charm'},
    {'name': 'Zen', 'icon': Icons.self_improvement, 'description': 'Minimalist & meditative'},
    {'name': 'Other (custom)', 'icon': Icons.edit, 'description': 'Create your own style'},
  ];
  String? _selectedGenre;
  
  // ========== CHARACTER CATEGORIES ==========
  final Map<String, List<String>> _characterCategories = {
    'Marvel': ['Iron Man', 'Spider-Man', 'Thor', 'Black Panther', 'Doctor Strange', 'Captain America', 'Scarlet Witch'],
    'DC Comics': ['Batman', 'Superman', 'Wonder Woman', 'Aquaman', 'The Flash', 'Green Lantern'],
    'Disney': ['Mickey Mouse', 'Elsa', 'Moana', 'Simba', 'Rapunzel', 'Mulan', 'Ariel'],
    'Pixar': ['Woody', 'Buzz Lightyear', 'Nemo', 'WALL-E', 'Joy', 'Remy', 'Miguel'],
    'Studio Ghibli': ['Totoro', 'Kiki', 'Howl', 'Chihiro', 'Princess Mononoke', 'Ponyo'],
    'Harry Potter': ['Dumbledore', 'Hermione', 'Luna Lovegood', 'Dobby', 'Hagrid', 'McGonagall'],
    'Anime': ['Goku', 'Naruto', 'Pikachu', 'Sailor Moon', 'Luffy', 'Tanjiro', 'Gojo'],
    'Classic Literature': ['Gandalf', 'Sherlock Holmes', 'Alice', 'Peter Pan', 'Atticus Finch', 'Mary Poppins'],
    'Greek Mythology': ['Zeus', 'Athena', 'Apollo', 'Poseidon', 'Artemis', 'Hermes'],
    'Historical Figures': ['Leonardo da Vinci', 'Marie Curie', 'Marcus Aurelius', 'Cleopatra', 'Einstein'],
  };
  String? _selectedCategory;
  String? _selectedCharacter;
  
  // Preset options for sleep goal
  final List<String> _goalOptions = [
    'Sleep 7-8 hours per night',
    'Fall asleep faster',
    'Reduce nighttime awakenings',
    'Improve sleep quality',
    'Reduce anxiety before sleep',
    'Wake up feeling refreshed',
    'Other (custom)',
  ];
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  @override
  void dispose() {
    _characterController.dispose();
    _goalController.dispose();
    _genreController.dispose();
    _previewPlayer.dispose();
    super.dispose();
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

    if (_isPreviewPlaying && _previewingVoiceId == voice.voiceId) {
      await _previewPlayer.stop();
      setState(() {
        _isPreviewPlaying = false;
        _previewingVoiceId = null;
      });
      return;
    }

    await _previewPlayer.stop();

    setState(() {
      _isPreviewPlaying = true;
      _previewingVoiceId = voice.voiceId;
    });

    try {
      await _previewPlayer.play(UrlSource(voice.previewUrl!));
      
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

  void _handleNext() {
    // Validate genre selection
    if (_selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a genre style')),
      );
      return;
    }
    
    // Validate custom genre if selected
    if (_selectedGenre == 'Other (custom)' && _genreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your custom genre')),
      );
      return;
    }
    
    // Validate character selection
    if (_selectedCharacter == null && _characterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a character')),
      );
      return;
    }
    
    // Validate goal selection
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sleep goal')),
      );
      return;
    }
    
    if (_selectedGoal == 'Other (custom)' && _goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your custom sleep goal')),
      );
      return;
    }
    
    // Validate voice selection
    if (_selectedVoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a voice')),
      );
      return;
    }

    // Build personalized config - use custom values where applicable
    final genreChoice = _selectedGenre == 'Other (custom)'
        ? _genreController.text.trim()
        : _selectedGenre!;
    final characterChoice = _selectedCharacter ?? _characterController.text.trim();
    final goalChoice = _selectedGoal == 'Other (custom)'
        ? _goalController.text.trim()
        : _selectedGoal!;

    final personalizedConfig = {
      'genre': genreChoice,
      'character_category': _selectedCategory,
      'character_choice': characterChoice,
      'goal': goalChoice,
      'voice_id': _selectedVoice!.voiceId,
      'voice_name': _selectedVoice!.name,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreExperimentReviewScreen(
          gender: widget.gender,
          swashResponses: widget.swashResponses,
          psqiResponses: widget.psqiResponses,
          personalizedConfig: personalizedConfig,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Personalized Hypnosis Setup'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Your Experience',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your personalized hypnosis preferences for the study',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const QuestionnaireProgressBar(currentStep: 4, totalSteps: 5),
              const SizedBox(height: 32),
              
              // Genre Selection
              _buildGenreSelector(),
              const SizedBox(height: 28),
              
              // Character Selection
              _buildCharacterSelector(),
              const SizedBox(height: 28),
              
              // Goal Input
              _buildGoalInput(),
              const SizedBox(height: 28),
              
              // Voice Selector
              _buildVoiceSelector(),
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
                      text: 'Next: Review',
                      icon: Icons.arrow_forward,
                      onPressed: _handleNext,
                      width: double.infinity,
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

  Widget _buildGenreSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.movie_filter, color: AppTheme.primaryPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Story Genre',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a narrative style for your hypnosis script',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _genreOptions.length,
          itemBuilder: (context, index) {
            final genre = _genreOptions[index];
            final isSelected = _selectedGenre == genre['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedGenre = genre['name']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.purpleBlueGradient : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      genre['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        genre['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Custom genre text field
        if (_selectedGenre == 'Other (custom)') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _genreController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your custom genre (e.g., Horror, Western, Comedy)...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.5)),
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
          ),
        ],
      ],
    );
  }

  Widget _buildCharacterSelector() {
    // Define category groups for cleaner organization
    final List<List<String>> categoryGroups = [
      ['Marvel', 'DC Comics', 'Disney', 'Pixar'],  // Entertainment
      ['Studio Ghibli', 'Anime', 'Harry Potter'],   // Animation & Fantasy
      ['Classic Literature', 'Greek Mythology', 'Historical Figures'],  // Others
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, color: AppTheme.primaryPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Character Guide',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a character whose style will guide your journey',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        
        // Category rows - compact layout
        ...categoryGroups.map((group) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: group.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = category;
                  _selectedCharacter = null;
                  _characterController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPurple
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPurple
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )),
        
        // Custom option row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = 'Custom';
              _selectedCharacter = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedCategory == 'Custom'
                    ? AppTheme.primaryPurple
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _selectedCategory == 'Custom'
                      ? AppTheme.primaryPurple
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                '✨ Custom',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: _selectedCategory == 'Custom' ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Characters in selected category with separator
        if (_selectedCategory != null && _selectedCategory != 'Custom') ...[
          // Separator with label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_selectedCategory Characters',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          // Character chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _characterCategories[_selectedCategory]!.map((character) {
              final isSelected = _selectedCharacter == character;
              return GestureDetector(
                onTap: () => setState(() => _selectedCharacter = character),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPurple
                          : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    character,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        // Custom character input
        if (_selectedCategory == 'Custom') ...[
          TextFormField(
            controller: _characterController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your custom character...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.5)),
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
          ),
        ],
        
        if (_selectedCategory == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: Colors.white.withValues(alpha: 0.4), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select a category above to see characters',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGoalInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag_outlined, color: AppTheme.primaryPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sleep Goal',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'What would you like to achieve with this hypnosis?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryPurple
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryPurple
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
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
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter your custom sleep goal...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
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
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.record_voice_over, color: AppTheme.primaryPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Voice',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
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
