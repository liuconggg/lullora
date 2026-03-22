// sleep_report.dart - Sleep data models

class SleepReport {
  final SleepSession session;
  final SleepStats? stats;
  final double missingDataRatio;
  final List<String> peculiarities;

  SleepReport({
    required this.session,
    this.stats,
    required this.missingDataRatio,
    required this.peculiarities,
  });

  factory SleepReport.fromJson(Map<String, dynamic> json) {
    return SleepReport(
      session: SleepSession.fromJson(json['session']),
      stats: json['stat'] != null ? SleepStats.fromJson(json['stat']) : null,
      missingDataRatio: json['missingDataRatio']?.toDouble() ?? 0.0,
      peculiarities: List<String>.from(json['peculiarities'] ?? []),
    );
  }
}

class SleepSession {
  final String id;
  final String state;
  final String createdTimezone;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? unexpectedEndTime;
  final List<int>? sleepStages;
  final List<int>? snoringStages;

  SleepSession({
    required this.id,
    required this.state,
    required this.createdTimezone,
    required this.startTime,
    this.endTime,
    this.unexpectedEndTime,
    this.sleepStages,
    this.snoringStages,
  });

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'] ?? json['sessionId'] ?? '',
      state: json['state'] ?? '',
      createdTimezone: json['createdTimezone'] ?? json['created_timezone'] ?? '',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : (json['sessionStartTime'] != null
              ? DateTime.parse(json['sessionStartTime'])
              : DateTime.now()),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : (json['sessionEndTime'] != null
              ? DateTime.parse(json['sessionEndTime'])
              : null),
      unexpectedEndTime: json['unexpectedEndTime'] != null
          ? DateTime.parse(json['unexpectedEndTime'])
          : null,
      sleepStages: json['sleepStages'] != null
          ? List<int>.from(json['sleepStages'])
          : null,
      snoringStages: json['snoringStages'] != null
          ? List<int>.from(json['snoringStages'])
          : null,
    );
  }
}

class SleepStats {
  // Sleep efficiency and timing
  final double? sleepEfficiency;
  final int? sleepLatency;
  final int? wakeupLatency;
  final DateTime? sleepTime;  // Changed from int - represents actual time of falling asleep
  final DateTime? wakeTime;   // Changed from int - represents actual wake time

  // Stage latencies
  final int? lightLatency;
  final int? deepLatency;
  final int? remLatency;

  // Time in each stage (in seconds)
  final int? timeInWake;
  final int? timeInSleep;
  final int? timeInBed;
  final int? timeInSleepPeriod;
  final int? timeInRem;
  final int? timeInLight;
  final int? timeInDeep;

  // Stage ratios
  final double? wakeRatio;
  final double? sleepRatio;
  final double? remRatio;
  final double? lightRatio;
  final double? deepRatio;

  // Snoring data
  final int? timeInSnoring;
  final int? timeInNoSnoring;
  final double? snoringRatio;
  final double? noSnoringRatio;
  final int? snoringCount;

  SleepStats({
    this.sleepEfficiency,
    this.sleepLatency,
    this.wakeupLatency,
    this.sleepTime,
    this.wakeTime,
    this.lightLatency,
    this.deepLatency,
    this.remLatency,
    this.timeInWake,
    this.timeInSleep,
    this.timeInBed,
    this.timeInSleepPeriod,
    this.timeInRem,
    this.timeInLight,
    this.timeInDeep,
    this.wakeRatio,
    this.sleepRatio,
    this.remRatio,
    this.lightRatio,
    this.deepRatio,
    this.timeInSnoring,
    this.timeInNoSnoring,
    this.snoringRatio,
    this.noSnoringRatio,
    this.snoringCount,
  });

  factory SleepStats.fromJson(Map<String, dynamic> json) {
    return SleepStats(
      sleepEfficiency: json['sleepEfficiency']?.toDouble(),
      sleepLatency: json['sleepLatency'],
      wakeupLatency: json['wakeupLatency'],
      sleepTime: json['sleepTime'] != null ? DateTime.parse(json['sleepTime']) : null,
      wakeTime: json['wakeTime'] != null ? DateTime.parse(json['wakeTime']) : null,
      lightLatency: json['lightLatency'],
      deepLatency: json['deepLatency'],
      remLatency: json['remLatency'],
      timeInWake: json['timeInWake'],
      timeInSleep: json['timeInSleep'],
      timeInBed: json['timeInBed'],
      timeInSleepPeriod: json['timeInSleepPeriod'],
      timeInRem: json['timeInRem'],
      timeInLight: json['timeInLight'],
      timeInDeep: json['timeInDeep'],
      wakeRatio: json['wakeRatio']?.toDouble(),
      sleepRatio: json['sleepRatio']?.toDouble(),
      remRatio: json['remRatio']?.toDouble(),
      lightRatio: json['lightRatio']?.toDouble(),
      deepRatio: json['deepRatio']?.toDouble(),
      timeInSnoring: json['timeInSnoring'],
      timeInNoSnoring: json['timeInNoSnoring'],
      snoringRatio: json['snoringRatio']?.toDouble(),
      noSnoringRatio: json['noSnoringRatio']?.toDouble(),
      snoringCount: json['snoringCount'],
    );
  }
}
