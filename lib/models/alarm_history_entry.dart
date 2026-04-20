class AlarmHistoryEntry {
  const AlarmHistoryEntry({
    required this.id,
    required this.alarmId,
    required this.challengeType,
    required this.difficulty,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.status,
    required this.actionTaken,
    required this.wrongAttempts,
  });

  final String id;
  final String alarmId;
  final String challengeType;
  final String difficulty;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final String status;
  final bool actionTaken;
  final int wrongAttempts;

  String get statusLabel {
    switch (status) {
      case 'success':
        return 'Reussie';
      case 'abandoned':
        return 'Non terminee';
      default:
        return status;
    }
  }

  factory AlarmHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return AlarmHistoryEntry(
      id: map['id'] as String? ?? '',
      alarmId: map['alarmId'] as String? ?? '',
      challengeType: map['challengeType'] as String? ?? 'math',
      difficulty: map['difficulty'] as String? ?? 'easy',
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['startedAtMillis'] as num?)?.toInt() ?? 0,
      ),
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['endedAtMillis'] as num?)?.toInt() ?? 0,
      ),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'unknown',
      actionTaken: map['actionTaken'] as bool? ?? false,
      wrongAttempts: (map['wrongAttempts'] as num?)?.toInt() ?? 0,
    );
  }
}