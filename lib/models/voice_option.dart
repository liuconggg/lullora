class VoiceOption {
  final String voiceId;
  final String name;
  final String? previewUrl;
  final String? category;
  final String? description;
  final List<String> labels;

  /// Rename mapping for generic or test voice names
  static const Map<String, String> _nameOverrides = {
    'test 1': 'Calm Male Voice',
    'test1': 'Calm Male Voice',
    'test 2': 'Gentle Female Voice',
    'test2': 'Gentle Female Voice',
    'test': 'Custom Voice',
    'Male Generated': 'Calm Male Voice',
    'Female Generated': 'Gentle Female Voice',
    'Cloned': 'Custom Voice',
  };

  VoiceOption({
    required this.voiceId,
    required this.name,
    this.previewUrl,
    this.category,
    this.description,
    this.labels = const [],
  });

  factory VoiceOption.fromJson(Map<String, dynamic> json) {
    // Extract labels from the labels map if present
    final labelsMap = json['labels'] as Map<String, dynamic>? ?? {};
    final labelsList = labelsMap.values.map((e) => e.toString().toLowerCase()).toList();
    
    // Get original name and apply override if exists
    final originalName = json['name'] as String;
    final displayName = _nameOverrides[originalName] ?? 
                        _nameOverrides[originalName.toLowerCase()] ?? 
                        originalName;
    
    return VoiceOption(
      voiceId: json['voice_id'] as String,
      name: displayName,
      previewUrl: json['preview_url'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      labels: labelsList,
    );
  }

  /// Check if this voice is suitable for hypnotherapy/meditation
  bool get isSuitableForHypnotherapy {
    final suitableKeywords = [
      'calm', 'soothing', 'relaxing', 'meditation', 'meditative',
      'gentle', 'soft', 'warm', 'deep', 'tranquil', 'peaceful',
      'asmr', 'narrator', 'narration', 'storytelling'
    ];
    
    // Check name
    final nameLower = name.toLowerCase();
    if (suitableKeywords.any((kw) => nameLower.contains(kw))) {
      return true;
    }
    
    // Check description
    if (description != null) {
      final descLower = description!.toLowerCase();
      if (suitableKeywords.any((kw) => descLower.contains(kw))) {
        return true;
      }
    }
    
    // Check labels
    for (final label in labels) {
      if (suitableKeywords.any((kw) => label.contains(kw))) {
        return true;
      }
    }
    
    return false;
  }

  Map<String, dynamic> toJson() => {
        'voice_id': voiceId,
        'name': name,
        if (previewUrl != null) 'preview_url': previewUrl,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        'labels': labels,
      };
}
