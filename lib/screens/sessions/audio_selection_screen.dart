import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/dynamic_hypnosis_session.dart';
import '../../services/dynamic_hypnosis_storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/safety_warning_card.dart';
import 'free_play_screen.dart';

class AudioSelectionScreen extends StatefulWidget {
  const AudioSelectionScreen({super.key});

  @override
  State<AudioSelectionScreen> createState() => _AudioSelectionScreenState();
}

class _AudioSelectionScreenState extends State<AudioSelectionScreen> {
  final _storageService = DynamicHypnosisStorageService();
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  
  List<DynamicHypnosisSession> _personalizedAudios = [];
  bool _isLoading = true;
  String? _participantId;

  @override
  void initState() {
    super.initState();
    _loadAudios();
  }

  Future<void> _loadAudios() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final participant = await _databaseService.getParticipantByUserId(userId);
      if (participant != null) {
        _participantId = participant.id;
        final audios = await _storageService.getAllForParticipant(participant.id);
        setState(() {
          _personalizedAudios = audios;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _playFixedAudio() {
    if (_participantId == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FreePlayScreen(
          participantId: _participantId!,
          isFixedAudio: true,
          audioAssetPath: 'audio/fixed_hypnosis.mp3',
        ),
      ),
    );
  }

  void _playPersonalizedAudio(DynamicHypnosisSession session) {
    if (_participantId == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FreePlayScreen(
          participantId: _participantId!,
          isFixedAudio: false,
          audioStoragePath: session.audioStoragePath,
          sessionTitle: '${session.characterChoice} - ${session.goal}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Select Audio'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Audio',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select an audio to play with sleep tracking',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Safety warning
                  const SafetyWarningCard(),
                  const SizedBox(height: 20),

                  // Fixed Audio Card
                  _buildAudioCard(
                    title: 'Standard Hypnosis',
                    subtitle: 'Pre-recorded 13-minute session',
                    icon: Icons.headphones,
                    isFixed: true,
                    onTap: _playFixedAudio,
                  ),

                  const SizedBox(height: 16),

                  // Personalized Audios
                  if (_personalizedAudios.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Your Personalized Sessions',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._personalizedAudios.map((session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAudioCard(
                        title: session.characterChoice,
                        subtitle: session.goal,
                        icon: Icons.psychology,
                        isFixed: false,
                        onTap: () => _playPersonalizedAudio(session),
                      ),
                    )),
                  ],

                  if (_personalizedAudios.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Create a personalized session to add more audios here',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildAudioCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isFixed,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isFixed
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                )
              : null,
          color: isFixed ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFixed
                ? AppTheme.primaryPurple.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isFixed
                    ? AppTheme.primaryPurple.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isFixed ? AppTheme.primaryPurple : Colors.white.withOpacity(0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: isFixed ? AppTheme.primaryPurple : Colors.white.withOpacity(0.5),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
