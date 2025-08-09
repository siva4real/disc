import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/timer_state.dart';
import 'database_service.dart';

class TimerService extends ChangeNotifier {
  Timer? _timer;
  TimerState _state = TimerState.initial();
  Session? _currentSession;

  TimerState get state => _state;
  Session? get currentSession => _currentSession;

  TimerService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    // Check if there's an active session on startup
    final activeSession = await DatabaseService.getActiveSession();
    if (activeSession != null) {
      _currentSession = activeSession;
      _state = TimerState(
        status: TimerStatus.paused, // Start as paused since app was closed
        elapsedSeconds: activeSession.durationSeconds,
        sessionStartTime: activeSession.startTime,
        currentSessionId: activeSession.id,
      );
      notifyListeners();
    }
  }

  Future<void> startTimer() async {
    if (_state.isRunning) return;

    DateTime sessionStartTime;
    int? sessionId;

    if (_currentSession == null) {
      // Create new session
      sessionStartTime = DateTime.now();
      final newSession = Session(
        startTime: sessionStartTime,
        durationSeconds: 0,
        isCompleted: false,
      );

      sessionId = await DatabaseService.insertSession(newSession);
      _currentSession = newSession.copyWith(id: sessionId);
    } else {
      // Resume existing session
      sessionStartTime = _currentSession!.startTime;
      sessionId = _currentSession!.id;
    }

    _state = _state.copyWith(
      status: TimerStatus.running,
      sessionStartTime: sessionStartTime,
      currentSessionId: sessionId,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _state = _state.copyWith(elapsedSeconds: _state.elapsedSeconds + 1);

      // Update session in database every 10 seconds to avoid too frequent writes
      if (_state.elapsedSeconds % 10 == 0) {
        _saveCurrentProgress();
      }

      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> pauseTimer() async {
    if (!_state.isRunning) return;

    _timer?.cancel();
    _state = _state.copyWith(status: TimerStatus.paused);

    await _saveCurrentProgress();
    notifyListeners();
  }

  Future<void> stopTimer() async {
    _timer?.cancel();

    if (_currentSession != null) {
      // Mark session as completed
      final completedSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        durationSeconds: _state.elapsedSeconds,
        isCompleted: true,
      );

      await DatabaseService.updateSession(completedSession);
    }

    _state = TimerState.initial();
    _currentSession = null;
    notifyListeners();
  }

  Future<void> resetTimer() async {
    _timer?.cancel();

    if (_currentSession != null) {
      // Delete the current session since it's being reset
      await DatabaseService.deleteSession(_currentSession!.id!);
    }

    _state = TimerState.initial();
    _currentSession = null;
    notifyListeners();
  }

  Future<void> _saveCurrentProgress() async {
    if (_currentSession != null) {
      final updatedSession = _currentSession!.copyWith(
        durationSeconds: _state.elapsedSeconds,
      );

      await DatabaseService.updateSession(updatedSession);
      _currentSession = updatedSession;
    }
  }

  // Analytics methods
  Future<int> getTodaysTotalSeconds() async {
    final today = DateTime.now();
    return await DatabaseService.getTotalSecondsForDate(today);
  }

  Future<List<Session>> getTodaysSessions() async {
    final today = DateTime.now();
    return await DatabaseService.getSessionsByDate(today);
  }

  Future<Map<DateTime, int>> getWeeklyData() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: 6));
    return await DatabaseService.getDailyTotalsForRange(startOfWeek, now);
  }

  Future<List<Session>> getAllSessions() async {
    return await DatabaseService.getAllSessions();
  }

  Future<int> getTotalSessionsCount() async {
    return await DatabaseService.getTotalSessionsCount();
  }

  Future<int> getTotalTimeSeconds() async {
    return await DatabaseService.getTotalTimeSeconds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
