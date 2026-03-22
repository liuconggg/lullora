class PreExperimentResponses {
  final String id;
  final String participantId;
  final String gender;
  final Map<String, dynamic> swashResponses;
  final Map<String, dynamic> psqiResponses;
  final DateTime completedAt;

  PreExperimentResponses({
    required this.id,
    required this.participantId,
    required this.gender,
    required this.swashResponses,
    required this.psqiResponses,
    required this.completedAt,
  });

  factory PreExperimentResponses.fromJson(Map<String, dynamic> json) {
    return PreExperimentResponses(
      id: json['id'] as String,
      participantId: json['participant_id'] as String,
      gender: json['gender'] as String,
      swashResponses: json['swash_responses'] as Map<String, dynamic>,
      psqiResponses: json['psqi_responses'] as Map<String, dynamic>,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_id': participantId,
      'gender': gender,
      'swash_responses': swashResponses,
      'psqi_responses': psqiResponses,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}

class PostExperimentResponses {
  final String id;
  final String participantId;
  final Map<String, dynamic> sassiResponses;
  final String? openFeedback;
  final DateTime completedAt;

  PostExperimentResponses({
    required this.id,
    required this.participantId,
    required this.sassiResponses,
    this.openFeedback,
    required this.completedAt,
  });

  factory PostExperimentResponses.fromJson(Map<String, dynamic> json) {
    return PostExperimentResponses(
      id: json['id'] as String,
      participantId: json['participant_id'] as String,
      sassiResponses: json['sassi_responses'] as Map<String, dynamic>,
      openFeedback: json['open_feedback'] as String?,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_id': participantId,
      'sassi_responses': sassiResponses,
      'open_feedback': openFeedback,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}
