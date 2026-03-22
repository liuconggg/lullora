// average_report.dart - Average sleep report models

class AverageReport {
  final Period period;
  final List<String> peculiarities;
  final AverageStats? averageStats;
  final int totalSessions;
  final int validSessions;
  final int invalidSessions;

  AverageReport({
    required this.period,
    required this.peculiarities,
    this.averageStats,
    required this.totalSessions,
    required this.validSessions,
    required this.invalidSessions,
  });

  factory AverageReport.fromJson(Map<String, dynamic> json) {
    // Calculate session counts from the session lists with safe null handling
    final sleptSessionsRaw = json['sleptSessions'];
    final neverSleptSessionsRaw = json['neverSleptSessions'];
    
    final sleptSessions = sleptSessionsRaw is List ? sleptSessionsRaw : [];
    final neverSleptSessions = neverSleptSessionsRaw is List ? neverSleptSessionsRaw : [];
    
    final totalSessions = sleptSessions.length + neverSleptSessions.length;
    
    return AverageReport(
      period: Period.fromJson(json['period'] ?? {}),
      peculiarities: List<String>.from(json['peculiarities'] ?? []),
      averageStats: json['averageStats'] != null 
          ? AverageStats.fromJson(json['averageStats']) 
          : null,
      totalSessions: totalSessions,
      validSessions: sleptSessions.length,
      invalidSessions: neverSleptSessions.length,
    );
  }
}

class Period {
  final String timezone;
  final DateTime startDate;
  final DateTime endDate;

  Period({
    required this.timezone,
    required this.startDate,
    required this.endDate,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      timezone: json['timezone'] ?? 'UTC',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : DateTime.now(),
    );
  }
}

class AverageStats {
  // Time strings (HH:mm:ss format)
  final String startTime;
  final String endTime;
  final String sleepTime;
  final String wakeTime;

  // Latencies (in seconds)
  final int sleepLatency;
  final int wakeupLatency;

  // Durations (in seconds)
  final int timeInBed;
  final int timeInSleepPeriod;
  final int timeInSleep;
  final int timeInWake;
  final int? timeInLight;
  final int? timeInDeep;
  final int? timeInRem;
  final int? timeInSnoring;
  final int? timeInNoSnoring;

  // Ratios (0-1 range as decimals)
  final double sleepEfficiency;
  final double wakeRatio;
  final double sleepRatio;
  final double? lightRatio;
  final double? deepRatio;
  final double? remRatio;
  final double? snoringRatio;
  final double? noSnoringRatio;

  // Counts
  final int wasoCount;
  final int longestWaso;
  final int sleepCycleCount;
  final int? snoringCount;

  AverageStats({
    required this.startTime,
    required this.endTime,
    required this.sleepTime,
    required this.wakeTime,
    required this.sleepLatency,
    required this.wakeupLatency,
    required this.timeInBed,
    required this.timeInSleepPeriod,
    required this.timeInSleep,
    required this.timeInWake,
    this.timeInLight,
    this.timeInDeep,
    this.timeInRem,
    this.timeInSnoring,
    this.timeInNoSnoring,
    required this.sleepEfficiency,
    required this.wakeRatio,
    required this.sleepRatio,
    this.lightRatio,
    this.deepRatio,
    this.remRatio,
    this.snoringRatio,
    this.noSnoringRatio,
    required this.wasoCount,
    required this.longestWaso,
    required this.sleepCycleCount,
    this.snoringCount,
  });

  factory AverageStats.fromJson(Map<String, dynamic> json) {
    return AverageStats(
      startTime: json['startTime'] ?? '00:00:00',
      endTime: json['endTime'] ?? '00:00:00',
      sleepTime: json['sleepTime'] ?? '00:00:00',
      wakeTime: json['wakeTime'] ?? '00:00:00',
      sleepLatency: json['sleepLatency'] ?? 0,
      wakeupLatency: json['wakeupLatency'] ?? 0,
      timeInBed: json['timeInBed'] ?? 0,
      timeInSleepPeriod: json['timeInSleepPeriod'] ?? 0,
      timeInSleep: json['timeInSleep'] ?? 0,
      timeInWake: json['timeInWake'] ?? 0,
      timeInLight: json['timeInLight'],
      timeInDeep: json['timeInDeep'],
      timeInRem: json['timeInRem'],
      timeInSnoring: json['timeInSnoring'],
      timeInNoSnoring: json['timeInNoSnoring'],
      sleepEfficiency: json['sleepEfficiency']?.toDouble() ?? 0.0,
      wakeRatio: json['wakeRatio']?.toDouble() ?? 0.0,
      sleepRatio: json['sleepRatio']?.toDouble() ?? 0.0,
      lightRatio: json['lightRatio']?.toDouble(),
      deepRatio: json['deepRatio']?.toDouble(),
      remRatio: json['remRatio']?.toDouble(),
      snoringRatio: json['snoringRatio']?.toDouble(),
      noSnoringRatio: json['noSnoringRatio']?.toDouble(),
      wasoCount: json['wasoCount'] ?? 0,
      longestWaso: json['longestWaso'] ?? 0,
      sleepCycleCount: json['sleepCycleCount'] ?? 0,
      snoringCount: json['snoringCount'],
    );
  }

  /// Format seconds to MM:SS or HH:MM:SS
  static String formatDuration(int seconds) {
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
}
