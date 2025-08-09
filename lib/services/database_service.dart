import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'discipline_timer.db';
  static const int _databaseVersion = 1;

  static const String _sessionsTable = 'sessions';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_sessionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Session CRUD operations
  static Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert(_sessionsTable, session.toMap());
  }

  static Future<Session?> getSession(int id) async {
    final db = await database;
    final maps = await db.query(
      _sessionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query(_sessionsTable, orderBy: 'start_time DESC');

    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }

  static Future<List<Session>> getSessionsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      _sessionsTable,
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'start_time ASC',
    );

    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }

  static Future<List<Session>> getSessionsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      _sessionsTable,
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'start_time ASC',
    );

    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }

  static Future<Session?> getActiveSession() async {
    final db = await database;
    final maps = await db.query(
      _sessionsTable,
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      _sessionsTable,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  static Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(_sessionsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Analytics methods
  static Future<int> getTotalSecondsForDate(DateTime date) async {
    final sessions = await getSessionsByDate(date);
    return sessions
        .where((session) => session.isCompleted)
        .fold<int>(0, (total, session) => total + session.durationSeconds);
  }

  static Future<Map<DateTime, int>> getDailyTotalsForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sessions = await getSessionsInRange(startDate, endDate);
    final Map<DateTime, int> dailyTotals = {};

    // Initialize all dates in range with 0
    DateTime currentDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      dailyTotals[currentDate] = 0;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Add session durations to appropriate dates
    for (final session in sessions) {
      if (session.isCompleted) {
        final sessionDate = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );
        dailyTotals[sessionDate] =
            (dailyTotals[sessionDate] ?? 0) + session.durationSeconds;
      }
    }

    return dailyTotals;
  }

  static Future<int> getTotalSessionsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $_sessionsTable WHERE is_completed = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getTotalTimeSeconds() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(duration_seconds) FROM $_sessionsTable WHERE is_completed = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Cleanup methods
  static Future<void> deleteOldSessions({int daysToKeep = 90}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await db.delete(
      _sessionsTable,
      where: 'start_time < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
