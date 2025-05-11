import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/flower.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _databaseName = "flowers.db";
  static const _databaseVersion = 10;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flowers (
        flowerid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        scientific_name TEXT NOT NULL,
        alias TEXT,
        family TEXT,
        genus TEXT,
        description TEXT NOT NULL,
        image_path TEXT NOT NULL,
        bloom_season TEXT NOT NULL,
        distribution TEXT,
        morphology TEXT,
        usage TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recognition_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        top1_flowerid TEXT NOT NULL,
        top1_confidence REAL NOT NULL,
        top2_flowerid TEXT,
        top2_confidence REAL,
        top3_flowerid TEXT,
        top3_confidence REAL,
        model_used TEXT,
        is_deleted INTEGER DEFAULT 0,
        note TEXT,
        deleted_at TEXT,
        FOREIGN KEY (top1_flowerid) REFERENCES flowers(flowerid),
        FOREIGN KEY (top2_flowerid) REFERENCES flowers(flowerid),
        FOREIGN KEY (top3_flowerid) REFERENCES flowers(flowerid)
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        flowerid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        image_path TEXT NOT NULL,
        FOREIGN KEY (flowerid) REFERENCES flowers(flowerid)
      )
    ''');

    await _loadInitialFlowers(db);
  }

  Future<void> _loadInitialFlowers(Database db) async {
    final jsonString = await rootBundle.loadString('assets/data/flowers.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    final batch = db.batch();
    for (final json in jsonList) {
      batch.insert(
        'flowers',
        {
          'flowerid': json['flowerid'],
          'name': json['name'],
          'scientific_name': json['scientific_name'],
          'alias': json['alias'],
          'family': json['family'],
          'genus': json['genus'],
          'description': json['description'],
          'image_path': json['image_path'],
          'bloom_season': json['bloom_season'],
          'distribution': json['distribution'],
          'morphology': json['morphology'],
          'usage': json['usage'],
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      await db.execute('ALTER TABLE recognition_history ADD COLUMN deleted_at TEXT');
      await db.execute('DROP TABLE IF EXISTS flowers');
      await db.execute('DROP TABLE IF EXISTS recognition_history');
      await db.execute('DROP TABLE IF EXISTS favorites');
      await _onCreate(db, newVersion);
    }
  }

  Future<List<Flower>> getAllFlowers() async {
    try {
      final db = await database;
      final maps = await db.query('flowers');
      return List.generate(maps.length, (i) => Flower.fromMap(maps[i]));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Flower>> searchFlowers(String query) async {
    try {
      final db = await database;
      final lowerQuery = query.toLowerCase();
      final result = await db.query(
        'flowers',
        where: 'LOWER(name) LIKE ? OR LOWER(scientific_name) LIKE ? OR LOWER(alias) LIKE ? OR LOWER(description) LIKE ?',
        whereArgs: ['%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%'],
      );
      return List.generate(result.length, (i) => Flower.fromMap(result[i]));
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecognitionRecord({
    required String imagePath,
    required List<Map<String, dynamic>> predictions,
    required String modelUsed,
    String? note,
  }) async {
    final db = await database;
    await db.insert('recognition_history', {
      'image_path': imagePath,
      'timestamp': DateTime.now().toIso8601String(),
      'top1_flowerid': predictions[0]['flowerId'],
      'top1_confidence': predictions[0]['confidence'],
      'top2_flowerid': predictions.length > 1 ? predictions[1]['flowerId'] : null,
      'top2_confidence': predictions.length > 1 ? predictions[1]['confidence'] : null,
      'top3_flowerid': predictions.length > 2 ? predictions[2]['flowerId'] : null,
      'top3_confidence': predictions.length > 2 ? predictions[2]['confidence'] : null,
      'model_used': modelUsed,
      'note': note,
      'is_deleted': 0,
      'deleted_at': null,
    });
  }

  Future<List<Map<String, dynamic>>> getRecognitionHistory() async {
    final db = await database;
    return await db.query(
      'recognition_history',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getDeletedRecords() async {
    final db = await database;
    return await db.query(
      'recognition_history',
      where: 'is_deleted = ?',
      whereArgs: [1],
      orderBy: 'deleted_at DESC',
    );
  }

  Future<void> softDeleteRecord(int id) async {
    final db = await database;
    await db.update(
      'recognition_history',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreRecord(int id) async {
    final db = await database;
    await db.update(
      'recognition_history',
      {
        'is_deleted': 0,
        'deleted_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDeleteRecord(int id) async {
    final db = await database;
    await db.delete(
      'recognition_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateNote(int id, String? note) async {
    final db = await database;
    await db.update(
      'recognition_history',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addFavorite(Flower flower) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'flowerid': flower.flowerId,
        'name': flower.name,
        'image_path': flower.imagePath,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorite(String flowerId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'flowerid = ?',
      whereArgs: [flowerId],
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    return await db.query('favorites');
  }

  Future<bool> isFavorite(String flowerId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'flowerid = ?',
      whereArgs: [flowerId],
    );
    return result.isNotEmpty;
  }
}