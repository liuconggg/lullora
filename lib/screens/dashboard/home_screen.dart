import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/sleep_session_state_service.dart';
import '../../models/participant.dart';
import '../../models/condition.dart';
import '../../models/nightly_session.dart';
import '../../widgets/gradient_button.dart';
import '../pre_experiment/demographics_screen.dart';
import '../nightly/night_session_screen.dart';
import '../nightly/normal_sleep_screen.dart';
import '../nightly/fixed_hypnosis_screen.dart';
import '../nightly/personalized_hypnosis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  
  Participant? _participant;
  bool _isLoading = true;
  bool _hasCompletedPreExperiment = false;

  @override
  void initState() {
    super.initState();
    _loadParticipant();
  }

  Future<void> _loadParticipant() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final participant = await _databaseService.getParticipantByUserId(userId);
      
      // Check if pre-experiment is completed
      bool preExperimentDone = false;
      if (participant != null) {
        preExperimentDone = await _databaseService.hasCompletedPreExperiment(participant.id);
      }
      
      setState(() {
        _participant = participant;
        _hasCompletedPreExperiment = preExperimentDone;
        _isLoading = false;
      });
      
      // Check for active tracking session
      if (participant != null && preExperimentDone) {
        _checkForActiveSession(participant.id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkForActiveSession(String participantId) async {
    final stateService = SleepSessionStateService();
    final activeSession = await stateService.getActiveTrackingSession(participantId);
    
    if (activeSession != null && mounted) {
      _showResumeSessionDialog(activeSession);
    }
  }

  void _showResumeSessionDialog(NightlySession session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.bedtime, color: AppTheme.primaryPurple, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sleep Session In Progress',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'You have an active sleep tracking session. Would you like to resume it or end it now?',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // End session and allow manual completion
              final stateService = SleepSessionStateService();
              await stateService.stopTracking(session.id);
            },
            child: const Text('End Session'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to appropriate session screen based on condition
              _resumeSession(session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _resumeSession(NightlySession session) {
    Widget screen;
    switch (session.condition) {
      case Condition.control:
        screen = NormalSleepScreen(sessionId: session.id);
        break;
      case Condition.fixed:
        screen = FixedHypnosisScreen(sessionId: session.id);
        break;
      case Condition.personalized:
        screen = PersonalizedHypnosisScreen(sessionId: session.id);
        break;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Call this when returning from enrollment/questionnaires
  void _refreshData() {
    setState(() => _isLoading = true);
    _loadParticipant();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isLoading && _participant != null && _hasCompletedPreExperiment)
          AppBar(
            title: const Text('Lullora'),
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
        Expanded(
          child: Container(
            color: AppTheme.darkBackground,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_participant == null || !_hasCompletedPreExperiment)
                    ? _buildEnrollmentPrompt()
                    : _buildStudyDashboard(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentPrompt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Welcome message
          Text(
            'Welcome to Lullora',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A research study on sleep quality improvement through hypnosis',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Study info card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.2),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.nights_stay,
                  size: 48,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to Our Sleep Study',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Participate in groundbreaking research exploring how hypnosis can improve sleep quality over a 3-night study period.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Quick facts
                _buildQuickFact(Icons.calendar_today, '3 Nights', 'Consecutive sleep sessions'),
                const SizedBox(height: 12),
                _buildQuickFact(Icons.assignment, 'Questionnaires', 'Pre, nightly, and post-study surveys'),
            
                const SizedBox(height: 32),
                
                // Enroll button
                GradientButton(
                  text: 'Get Started',
                  icon: Icons.arrow_forward,
                  onPressed: () async {
                    // Go directly to demographics questionnaire
                    // Participant will be created when questionnaires are submitted
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DemographicsScreen(),
                      ),
                    );
                    // Refresh data when user returns
                    _refreshData();
                  },
                  width: double.infinity,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info note
        ],
      ),
    );
  }

  Widget _buildQuickFact(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudyDashboard() {
    final isStudyComplete = _participant!.currentNight == 4;
    
    // Calculate nights completed: if study is complete, all 3 nights are done
    // Otherwise, it's currentNight - 1 (since currentNight is the next night to do)
    final nightsCompleted = isStudyComplete ? 3 : (_participant!.currentNight - 1).clamp(0, 3);
    
    final overallProgress = isStudyComplete ? 1.0 : (nightsCompleted / 3);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isStudyComplete ? 'Study Complete! 🎉' : 'Your Sleep Study',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isStudyComplete
                ? 'Thank you for participating in our research study'
                : 'Track your progress through the 3-night study',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),

          // Progress cards
          Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  title: 'Pre-Experiment',
                  value: 'Complete',
                  icon: Icons.check_circle,
                  iconColor: AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressCard(
                  title: 'Nights Completed',
                  value: '$nightsCompleted / 3',
                  icon: Icons.nightlight_round,
                  iconColor: AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressCard(
            title: 'Overall Progress',
            value: '${(overallProgress * 100).toInt()}%',
            icon: Icons.show_chart,
            iconColor: AppTheme.primaryPurple,
            showProgressBar: true,
            progress: overallProgress,
          ),

          const SizedBox(height: 32),

          // Next Step card or completion message
          if (!isStudyComplete && _participant!.currentNight <= 3) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleBlueGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Step',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for Night ${_participant!.currentNight}?',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _handleStartNight,
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: Text('Start Night ${_participant!.currentNight}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isStudyComplete) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentGreen.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    color: AppTheme.accentGreen,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Study Complete!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you for participating in our research study. Your contribution helps us understand how hypnosis affects sleep quality. Your data has been recorded and will contribute to advancing sleep science.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          const SizedBox(height: 16),

        ],
      ),
    );
  }

  void _handleStartNight() {
    final nightIndex = _participant!.currentNight - 1;
    final condition = _participant!.conditionOrder[nightIndex];
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NightSessionScreen(
          participantId: _participant!.id,
          nightNumber: _participant!.currentNight,
          condition: condition,
        ),
      ),
    ).then((_) => _loadParticipant());
  }



  Widget _buildProgressCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool showProgressBar = false,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (showProgressBar && progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

}
