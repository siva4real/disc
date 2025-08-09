class Session {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final bool isCompleted;

  Session({
    this.id,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.isCompleted,
  });

  Session copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    bool? isCompleted,
  }) {
    return Session(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id']?.toInt(),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      durationSeconds: map['duration_seconds']?.toInt() ?? 0,
      isCompleted: (map['is_completed'] ?? 0) == 1,
    );
  }

  Duration get duration => Duration(seconds: durationSeconds);

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedTime {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final remainingSeconds = durationSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Session(id: $id, startTime: $startTime, endTime: $endTime, durationSeconds: $durationSeconds, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.durationSeconds == durationSeconds &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        durationSeconds.hashCode ^
        isCompleted.hashCode;
  }
}
