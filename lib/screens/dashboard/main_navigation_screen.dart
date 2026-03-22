import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/participant.dart';
import '../../models/condition.dart';
import 'home_screen.dart';
import '../sessions/sessions_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const MainNavigationScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  Participant? _participant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _loadParticipant();
  }

  Future<void> _loadParticipant() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final participant = await _databaseService.getParticipantByUserId(userId);
      if (mounted) {
        setState(() {
          _participant = participant;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isStudyComplete => _participant?.currentNight == 4;

  void _onTabTapped(int index) {
    // Check if trying to access Sessions tab while study incomplete
    if (index == 1 && !_isStudyComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complete all 3 study nights to unlock Sessions'),
          backgroundColor: AppTheme.primaryPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      const HomeScreen(),
      const SessionsScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.borderColor.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardBackground,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined),
              activeIcon: Icon(Icons.science),
              label: 'Study',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(
                    Icons.headphones_outlined,
                    color: _isStudyComplete 
                        ? (_currentIndex == 1 ? AppTheme.primaryPurple : Colors.white.withOpacity(0.5))
                        : Colors.white.withOpacity(0.3),
                  ),
                  if (!_isStudyComplete)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.lock,
                        size: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.headphones),
              label: 'Sessions',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
