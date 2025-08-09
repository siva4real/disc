enum TimerStatus { initial, running, paused, stopped }

class TimerState {
  final TimerStatus status;
  final int elapsedSeconds;
  final DateTime? sessionStartTime;
  final int? currentSessionId;

  const TimerState({
    required this.status,
    required this.elapsedSeconds,
    this.sessionStartTime,
    this.currentSessionId,
  });

  factory TimerState.initial() {
    return const TimerState(status: TimerStatus.initial, elapsedSeconds: 0);
  }

  TimerState copyWith({
    TimerStatus? status,
    int? elapsedSeconds,
    DateTime? sessionStartTime,
    int? currentSessionId,
  }) {
    return TimerState(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isStopped => status == TimerStatus.stopped;
  bool get isInitial => status == TimerStatus.initial;

  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final remainingSeconds = elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'TimerState(status: $status, elapsedSeconds: $elapsedSeconds, sessionStartTime: $sessionStartTime, currentSessionId: $currentSessionId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerState &&
        other.status == status &&
        other.elapsedSeconds == elapsedSeconds &&
        other.sessionStartTime == sessionStartTime &&
        other.currentSessionId == currentSessionId;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        elapsedSeconds.hashCode ^
        sessionStartTime.hashCode ^
        currentSessionId.hashCode;
  }
}
