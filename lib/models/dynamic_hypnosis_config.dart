class DynamicHypnosisConfig {
  final String characterChoice;
  final String goal;
  final String voiceId;
  final String voiceName;

  DynamicHypnosisConfig({
    required this.characterChoice,
    required this.goal,
    required this.voiceId,
    required this.voiceName,
  });

  Map<String, dynamic> toJson() => {
        'characterChoice': characterChoice,
        'goal': goal,
        'voiceId': voiceId,
        'voiceName': voiceName,
      };

  factory DynamicHypnosisConfig.fromJson(Map<String, dynamic> json) {
    return DynamicHypnosisConfig(
      characterChoice: json['characterChoice'] as String,
      goal: json['goal'] as String,
      voiceId: json['voiceId'] as String,
      voiceName: json['voiceName'] as String,
    );
  }

  // Generate a unique cache key based on character and goal
  String get cacheKey {
    return '${characterChoice.toLowerCase().replaceAll(' ', '_')}_${goal.toLowerCase().replaceAll(' ', '_').substring(0, goal.length > 20 ? 20 : goal.length)}';
  }
}
