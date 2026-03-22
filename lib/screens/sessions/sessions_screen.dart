import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/dynamic_hypnosis_storage_service.dart';
import 'audio_selection_screen.dart';
import 'free_personalized_setup_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _storageService = DynamicHypnosisStorageService();
  
  bool _isLoading = true;
  int _customisationCount = 0;
  static const int _maxCustomisations = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final participant = await _databaseService.getParticipantByUserId(userId);
      if (participant != null) {
        final count = await _storageService.getSessionCount(participant.id);
        if (mounted) {
          setState(() {
            _customisationCount = count;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasCustomisationsRemaining => _customisationCount < _maxCustomisations;
  int get _customisationsRemaining => (_maxCustomisations - _customisationCount).clamp(0, _maxCustomisations);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Hypnosis Sessions'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a Session',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enjoy unlimited access to hypnosis sessions with sleep tracking',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Fixed Session - always available
                  _buildSessionCard(
                    context: context,
                    title: 'Fixed Hypnosis Session',
                    description: 'Choose from available audio sessions',
                    icon: Icons.headphones,
                    gradient: AppTheme.purpleBlueGradient,
                    badge: null,
                    isEnabled: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AudioSelectionScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Personalized Session - limited
                  _buildSessionCard(
                    context: context,
                    title: 'Create New Personalized',
                    description: _hasCustomisationsRemaining
                        ? 'Generate a custom hypnosis session'
                        : 'You have used your free customisation',
                    icon: Icons.psychology,
                    gradient: LinearGradient(
                      colors: _hasCustomisationsRemaining
                          ? [AppTheme.primaryPurple, const Color(0xFF9C27B0)]
                          : [Colors.grey.shade700, Colors.grey.shade800],
                    ),
                    badge: _hasCustomisationsRemaining
                        ? '$_customisationsRemaining remaining'
                        : 'Limit reached',
                    isEnabled: _hasCustomisationsRemaining,
                    onTap: _hasCustomisationsRemaining
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FreePersonalizedSetupScreen(),
                              ),
                            );
                          }
                        : null,
                  ),

                  const SizedBox(height: 32),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          color: AppTheme.primaryPurple.withOpacity(0.8),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All sessions include sleep tracking via Asleep SDK',
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

  Widget _buildSessionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required bool isEnabled,
    String? badge,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? Colors.white.withOpacity(0.2)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isEnabled ? Icons.chevron_right : Icons.lock,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
