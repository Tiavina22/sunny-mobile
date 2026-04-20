class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.challengeType,
    required this.difficulty,
  });

  final String id;
  final int hour;
  final int minute;
  final bool enabled;
  final ChallengeType challengeType;
  final AlarmDifficulty difficulty;

  String get formattedTime {
    final String hourText = hour.toString().padLeft(2, '0');
    final String minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? enabled,
    ChallengeType? challengeType,
    AlarmDifficulty? difficulty,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      challengeType: challengeType ?? this.challengeType,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
      'challengeType': challengeType.name,
      'difficulty': difficulty.name,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    final String challengeRaw = (json['challengeType'] as String?) ?? '';
    final String difficultyRaw = (json['difficulty'] as String?) ?? '';

    return Alarm(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      enabled: json['enabled'] as bool? ?? true,
      challengeType: ChallengeType.values.firstWhere(
        (ChallengeType value) => value.name == challengeRaw,
        orElse: () => ChallengeType.math,
      ),
      difficulty: AlarmDifficulty.values.firstWhere(
        (AlarmDifficulty value) => value.name == difficultyRaw,
        orElse: () => AlarmDifficulty.easy,
      ),
    );
  }
}

enum ChallengeType {
  math('Math'),
  photo('Photo'),
  quote('Quote / Bible');

  const ChallengeType(this.label);
  final String label;
}

enum AlarmDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const AlarmDifficulty(this.label);
  final String label;
}