enum Condition {
  control('control', 'Normal Sleep'),
  fixed('fixed', 'Fixed Hypnosis'),
  personalized('personalized', 'Personalized Hypnosis');

  final String value;
  final String displayName;
  
  const Condition(this.value, this.displayName);
  
  static Condition fromString(String value) {
    return Condition.values.firstWhere(
      (condition) => condition.value == value,
      orElse: () => Condition.control,
    );
  }
}

enum StudyStatus {
  preExperiment('pre_experiment'),
  inProgress('in_progress'),
  completed('completed');

  final String value;
  
  const StudyStatus(this.value);
  
  static StudyStatus fromString(String value) {
    return StudyStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StudyStatus.preExperiment,
    );
  }
}

