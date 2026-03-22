import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../models/sleep_report.dart';
import '../../models/average_report.dart';
import '../../services/asleep_service.dart';
import 'sleep_report_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _asleepService = AsleepService();
  
  late TabController _tabController;
  List<SleepSession>? _sessionList;
  AverageReport? _averageReport;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user's participant ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not logged in');
      }

      final participantResponse = await _supabase
          .from('study_participants')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (participantResponse == null) {
        setState(() {
          _sessionList = [];
          _isLoading = false;
        });
        return;
      }

      final participantId = participantResponse['id'] as String;
      print('Analytics: Found participant ID: $participantId');

      // Reinitialize Asleep SDK to get fresh data from database
      final initialized = await _asleepService.reinitialize(
        participantId: participantId,
      );
      
      if (!initialized) {
        throw Exception('Failed to initialize Asleep SDK');
      }

      final now = DateTime.now();
      // Last 7 days for average report
      final last7DaysStart = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
      // Last year for session list
      final lastYearStart = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 365)));
      final today = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      
      print('Analytics: Fetching average report from $last7DaysStart to $today');
      print('Analytics: Fetching session list from $lastYearStart to $today');
      
      // Fetch both average report and session list
      final averageReport = await _asleepService.getAverageReport(
        fromDate: last7DaysStart,
        toDate: today,
      );
      
      final reportList = await _asleepService.getReportList(
        fromDate: lastYearStart,
        toDate: today,
      );

      print('Analytics: Found ${reportList.length} sessions from Asleep SDK');
      print('Analytics: Average report loaded: ${averageReport != null}');

      setState(() {
        _sessionList = reportList;
        _averageReport = averageReport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading analytics: $e');
    }
  }

  /// Fetch full report and navigate to detail screen
  Future<void> _onSessionTap(SleepSession session) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
      ),
    );

    try {
      print('Analytics: Fetching full report for session ${session.id}');
      final report = await _asleepService.getReport(session.id);
      
      if (!mounted) return;
      
      // Close loading indicator
      Navigator.pop(context);
      
      if (report != null) {
        // Navigate to detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SleepReportDetailScreen(report: report),
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load sleep report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Close loading indicator
      Navigator.pop(context);
      
      print('Error fetching report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Sleep Analytics'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Report'),
            Tab(text: 'Sessions'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading analytics',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildReportTab(),
        _buildSessionsTab(),
      ],
    );
  }

  Widget _buildReportTab() {
    if (_averageReport == null || _averageReport!.averageStats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bedtime_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Data Available',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete more sleep sessions to see average statistics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _averageReport!.averageStats!;
    final period = _averageReport!.period;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period header
          _buildPeriodCard(period),
          const SizedBox(height: 20),
          
          // Session summary
          _buildSessionSummaryCard(),
          const SizedBox(height: 20),
          
          // Average statistics
          Text(
            'Summary of Sleep Analysis',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildAverageStatsGrid(stats),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(Period period) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.2),
            AppTheme.primaryBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Last 7 days',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${dateFormat.format(period.startDate)} ~ ${dateFormat.format(period.endDate)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSessionCount('Total', _averageReport!.totalSessions, AppTheme.primaryPurple),
          _buildSessionCount('Valid', _averageReport!.validSessions, AppTheme.accentGreen),
          _buildSessionCount('Invalid', _averageReport!.invalidSessions, AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildSessionCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAverageStatsGrid(AverageStats stats) {
    return Column(
      children: [
        _buildStatRow('Sleep efficiency', '${(stats.sleepEfficiency * 100).toStringAsFixed(1)}%'),
        _buildStatRow('Time in bed', AverageStats.formatDuration(stats.timeInBed)),
        _buildStatRow('Time in sleep', AverageStats.formatDuration(stats.timeInSleep)),
        _buildStatRow('Sleep latency', AverageStats.formatDuration(stats.sleepLatency)),
        _buildStatRow('WASO count', '${stats.wasoCount} times'),
        _buildStatRow('Wake ratio', '${(stats.wakeRatio * 100).toStringAsFixed(1)}%'),
        if (stats.remRatio != null)
          _buildStatRow('REM ratio', '${(stats.remRatio! * 100).toStringAsFixed(1)}%'),
        if (stats.lightRatio != null)
          _buildStatRow('Light ratio', '${(stats.lightRatio! * 100).toStringAsFixed(1)}%'),
        if (stats.deepRatio != null)
          _buildStatRow('Deep ratio', '${(stats.deepRatio! * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_sessionList == null || _sessionList!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bedtime_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Sleep Sessions Yet',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your first sleep session to see it here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _sessionList!.length,
      itemBuilder: (context, index) {
        final session = _sessionList![index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(SleepSession session) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    // Convert UTC to local timezone
    final localStartTime = session.startTime.toLocal();
    final startDate = dateFormat.format(localStartTime);
    final startTime = timeFormat.format(localStartTime);
    
    // Calculate duration if end time exists
    String? duration;
    if (session.endTime != null) {
      final diff = session.endTime!.difference(session.startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      duration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    }
    
    // State color
    Color stateColor;
    switch (session.state) {
      case 'COMPLETE':
        stateColor = AppTheme.accentGreen;
        break;
      case 'CLOSED':
        stateColor = Colors.orange;
        break;
      case 'OPEN':
        stateColor = AppTheme.primaryPurple;
        break;
      default:
        stateColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackground,
            AppTheme.cardBackground.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSessionTap(session),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with date and state badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            startDate,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Started at $startTime',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // State badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: stateColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: stateColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        session.state,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: stateColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (duration != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.bedtime,
                        size: 20,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        duration,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                // Tap to view indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to view full report',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryPurple.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppTheme.primaryPurple.withOpacity(0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
