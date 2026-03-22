import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/sleep_report.dart';

class SleepReportDetailScreen extends StatelessWidget {
  final SleepReport report;

  const SleepReportDetailScreen({
    super.key,
    required this.report,
  });

  /// Format seconds to readable duration
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  /// Format percentage
  String _formatPercentage(double? ratio) {
    if (ratio == null) return 'N/A';
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final session = report.session;
    final stats = report.stats;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Sleep Report'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session header card
            _buildSessionHeader(session, dateFormat, timeFormat),
            const SizedBox(height: 24),

            if (stats != null) ...[
              // Sleep Summary Section
              _buildSectionTitle('Sleep Summary'),
              const SizedBox(height: 16),
              _buildSleepSummary(stats),
              const SizedBox(height: 24),

              // Time Distribution
              _buildSectionTitle('Time Distribution'),
              const SizedBox(height: 16),
              _buildTimeDistribution(stats),
              const SizedBox(height: 24),

              // Sleep Stages
              _buildSectionTitle('Sleep Stage Analysis'),
              const SizedBox(height: 16),
              _buildSleepStages(stats),
              const SizedBox(height: 24),

              // Latencies
              _buildSectionTitle('Sleep Latencies'),
              const SizedBox(height: 16),
              _buildLatencies(stats),
              const SizedBox(height: 24),

              // Snoring data if available
              if (stats.snoringCount != null) ...[
                _buildSectionTitle('Snoring Analysis'),
                const SizedBox(height: 16),
                _buildSnoringData(stats),
              ],
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Text(
                    'No sleep statistics available for this session',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader(SleepSession session, DateFormat dateFormat, DateFormat timeFormat) {
    // Convert UTC times to local timezone
    final localStartTime = session.startTime.toLocal();
    final localEndTime = session.endTime?.toLocal();
    
    final startDate = dateFormat.format(localStartTime);
    final startTime = timeFormat.format(localStartTime);
    final endTime = localEndTime != null ? timeFormat.format(localEndTime) : null;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startDate,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
          const SizedBox(height: 12),
          _buildHeaderRow(Icons.play_arrow, 'Started', startTime),
          if (endTime != null) ...[
            const SizedBox(height: 8),
            _buildHeaderRow(Icons.stop, 'Ended', endTime),
          ],
          const SizedBox(height: 8),
          _buildHeaderRow(Icons.location_on, 'Timezone', session.createdTimezone),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSleepSummary(SleepStats stats) {
    return Column(
      children: [
        _buildStatRow('Sleep Efficiency', _formatPercentage(stats.sleepEfficiency)),
        if (stats.sleepTime != null)
          _buildStatRow('Sleep Time', DateFormat('HH:mm').format(stats.sleepTime!.toLocal())),
        if (stats.wakeTime != null)
          _buildStatRow('Wake Time', DateFormat('HH:mm').format(stats.wakeTime!.toLocal())),
      ],
    );
  }

  Widget _buildTimeDistribution(SleepStats stats) {
    return Column(
      children: [
        if (stats.timeInBed != null)
          _buildStatRow('Time in Bed', _formatDuration(stats.timeInBed!)),
        if (stats.timeInSleep != null)
          _buildStatRow('Time in Sleep', _formatDuration(stats.timeInSleep!)),
        if (stats.timeInSleepPeriod != null)
          _buildStatRow('Sleep Period', _formatDuration(stats.timeInSleepPeriod!)),
        if (stats.timeInWake != null)
          _buildStatRow('Time Awake', _formatDuration(stats.timeInWake!)),
      ],
    );
  }

  Widget _buildSleepStages(SleepStats stats) {
    return Column(
      children: [
        // Ratios
        if (stats.remRatio != null)
          _buildStatRow('REM Sleep', _formatPercentage(stats.remRatio)),
        if (stats.lightRatio != null)
          _buildStatRow('Light Sleep', _formatPercentage(stats.lightRatio)),
        if (stats.deepRatio != null)
          _buildStatRow('Deep Sleep', _formatPercentage(stats.deepRatio)),
        if (stats.wakeRatio != null)
          _buildStatRow('Wake Ratio', _formatPercentage(stats.wakeRatio)),
        if (stats.sleepRatio != null)
          _buildStatRow('Sleep Ratio', _formatPercentage(stats.sleepRatio)),
        
        const SizedBox(height: 16),
        
        // Time in each stage
        if (stats.timeInRem != null)
          _buildStatRow('REM Duration', _formatDuration(stats.timeInRem!)),
        if (stats.timeInLight != null)
          _buildStatRow('Light Duration', _formatDuration(stats.timeInLight!)),
        if (stats.timeInDeep != null)
          _buildStatRow('Deep Duration', _formatDuration(stats.timeInDeep!)),
      ],
    );
  }

  Widget _buildLatencies(SleepStats stats) {
    return Column(
      children: [
        if (stats.sleepLatency != null)
          _buildStatRow('Sleep Latency', _formatDuration(stats.sleepLatency!)),
        if (stats.wakeupLatency != null)
          _buildStatRow('Wakeup Latency', _formatDuration(stats.wakeupLatency!)),
        if (stats.remLatency != null)
          _buildStatRow('REM Latency', _formatDuration(stats.remLatency!)),
        if (stats.lightLatency != null)
          _buildStatRow('Light Latency', _formatDuration(stats.lightLatency!)),
        if (stats.deepLatency != null)
          _buildStatRow('Deep Latency', _formatDuration(stats.deepLatency!)),
      ],
    );
  }

  Widget _buildSnoringData(SleepStats stats) {
    return Column(
      children: [
        if (stats.snoringCount != null)
          _buildStatRow('Snoring Count', '${stats.snoringCount} times'),
        if (stats.snoringRatio != null)
          _buildStatRow('Snoring Ratio', _formatPercentage(stats.snoringRatio)),
        if (stats.noSnoringRatio != null)
          _buildStatRow('No Snoring', _formatPercentage(stats.noSnoringRatio)),
        if (stats.timeInSnoring != null)
          _buildStatRow('Time Snoring', _formatDuration(stats.timeInSnoring!)),
        if (stats.timeInNoSnoring != null)
          _buildStatRow('Time Not Snoring', _formatDuration(stats.timeInNoSnoring!)),
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
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
}
