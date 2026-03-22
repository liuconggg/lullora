import 'condition.dart';

class NightlySession {
  final String id;
  final String participantId;
  final int nightNumber;
  final Condition condition;
  final String sessionDate;
  final Map<String, dynamic>? preSleepResponses;
  final Map<String, dynamic>? postSleepResponses;
  final Map<String, dynamic>? sleepMetrics;
  final Map<String, dynamic>? personalizationInputs;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  // Sleep tracking state fields
  final String trackingState; // 'not_started', 'tracking', 'stopped', 'completed'
  final DateTime? trackingStartedAt;
  final DateTime? trackingStoppedAt;
  final String? asleepSessionId; // Asleep SDK session ID for fetching reports

  const NightlySession({
    required this.id,
    required this.participantId,
    required this.nightNumber,
    required this.condition,
    required this.sessionDate,
    this.preSleepResponses,
    this.postSleepResponses,
    this.sleepMetrics,
    this.personalizationInputs,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.trackingState = 'not_started',
    this.trackingStartedAt,
    this.trackingStoppedAt,
    this.asleepSessionId,
  });

  factory NightlySession.fromJson(Map<String, dynamic> json) {
    return NightlySession(
      id: json['id'] as String,
      participantId: json['participant_id'] as String,
      nightNumber: json['night_number'] as int,
      condition: Condition.fromString(json['condition'] as String),
      sessionDate: json['session_date'] as String,
      preSleepResponses: json['pre_sleep_responses'] as Map<String, dynamic>?,
      postSleepResponses: json['post_sleep_responses'] as Map<String, dynamic>?,
      sleepMetrics: json['sleep_metrics'] as Map<String, dynamic>?,
      personalizationInputs: json['personalization_inputs'] as Map<String, dynamic>?,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      trackingState: json['tracking_state'] as String? ?? 'not_started',
      trackingStartedAt: json['tracking_started_at'] != null
          ? DateTime.parse(json['tracking_started_at'] as String)
          : null,
      trackingStoppedAt: json['tracking_stopped_at'] != null
          ? DateTime.parse(json['tracking_stopped_at'] as String)
          : null,
      asleepSessionId: json['asleep_session_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_id': participantId,
      'night_number': nightNumber,
      'condition': condition.value,
      'session_date': sessionDate,
      'created_at': createdAt.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (preSleepResponses != null) 'pre_sleep_responses': preSleepResponses,
      if (postSleepResponses != null) 'post_sleep_responses': postSleepResponses,
      if (sleepMetrics != null) 'sleep_metrics': sleepMetrics,
      if (personalizationInputs != null) 'personalization_inputs': personalizationInputs,
      'tracking_state': trackingState,
      if (trackingStartedAt != null) 'tracking_started_at': trackingStartedAt!.toIso8601String(),
      if (trackingStoppedAt != null) 'tracking_stopped_at': trackingStoppedAt!.toIso8601String(),
      if (asleepSessionId != null) 'asleep_session_id': asleepSessionId,
    };
  }

  bool get isCompleted => completedAt != null;
  
  NightlySession copyWith({
    String? id,
    String? participantId,
    int? nightNumber,
    Condition? condition,
    String? sessionDate,
    Map<String, dynamic>? preSleepResponses,
    Map<String, dynamic>? postSleepResponses,
    Map<String, dynamic>? sleepMetrics,
    Map<String, dynamic>? personalizationInputs,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return NightlySession(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      nightNumber: nightNumber ?? this.nightNumber,
      condition: condition ?? this.condition,
      sessionDate: sessionDate ?? this.sessionDate,
      preSleepResponses: preSleepResponses ?? this.preSleepResponses,
      postSleepResponses: postSleepResponses ?? this.postSleepResponses,
      sleepMetrics: sleepMetrics ?? this.sleepMetrics,
      personalizationInputs: personalizationInputs ?? this.personalizationInputs,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
