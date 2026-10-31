
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static const String dbName = 'rafiq_student.db';
  static const String favoritesTable = 'favorites';
  static const String progressTable = 'progress';
  static const String completedLessonsTable = 'completed_lessons';

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), dbName);

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE $favoritesTable (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        addedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $progressTable (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        completedLessons INTEGER NOT NULL,
        totalLessons INTEGER NOT NULL,
        progressPercentage REAL NOT NULL,
        lastAccessDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $completedLessonsTable (
        id TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        courseId TEXT NOT NULL,
        completedAt TEXT NOT NULL
      )
    ''');
  }

  // المفضلة

  static Future<void> addFavorite(String courseId) async {
    final db = await database;

    await db.insert(
      favoritesTable,
      {
        'id': '${courseId}_fav',
        'courseId': courseId,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeFavorite(String courseId) async {
    final db = await database;

    await db.delete(
      favoritesTable,
      where: 'courseId = ?',
      whereArgs: [courseId],
    );
  }

  static Future<List<String>> getFavorites() async {
    final db = await database;

    final results = await db.query(
      favoritesTable,
      orderBy: 'addedAt DESC',
    );

    return results
        .map((row) => row['courseId'] as String)
        .toList();
  }

  static Future<bool> isFavorite(String courseId) async {
    final db = await database;

    final result = await db.query(
      favoritesTable,
      where: 'courseId = ?',
      whereArgs: [courseId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // التقدم الدراسي

  static Future<void> saveProgress(
    String courseId,
    int completedLessons,
    int totalLessons,
  ) async {
    final db = await database;

    final safeTotal = totalLessons < 0 ? 0 : totalLessons;
    final safeCompleted = completedLessons < 0
        ? 0
        : (completedLessons > safeTotal
            ? safeTotal
            : completedLessons);

    final percentage = safeTotal == 0
        ? 0.0
        : (safeCompleted / safeTotal) * 100;

    await db.insert(
      progressTable,
      {
        'id': '${courseId}_progress',
        'courseId': courseId,
        'completedLessons': safeCompleted,
        'totalLessons': safeTotal,
        'progressPercentage': percentage,
        'lastAccessDate': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getProgress(
    String courseId,
  ) async {
    final db = await database;

    final result = await db.query(
      progressTable,
      where: 'courseId = ?',
      whereArgs: [courseId],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  // الدروس المكتملة

  static Future<void> markLessonCompleted(
    String lessonId,
    String courseId,
  ) async {
    final db = await database;

    await db.insert(
      completedLessonsTable,
      {
        'id': '${lessonId}_completed',
        'lessonId': lessonId,
        'courseId': courseId,
        'completedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<String>> getCompletedLessons(
    String courseId,
  ) async {
    final db = await database;

    final results = await db.query(
      completedLessonsTable,
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'completedAt DESC',
    );

    return results
        .map((row) => row['lessonId'] as String)
        .toList();
  }

  static Future<bool> isLessonCompleted(
    String lessonId,
  ) async {
    final db = await database;

    final result = await db.query(
      completedLessonsTable,
      where: 'lessonId = ?',
      whereArgs: [lessonId],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}
