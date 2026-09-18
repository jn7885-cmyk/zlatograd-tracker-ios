import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class QueuedPoint {
  const QueuedPoint(this.id, this.payload);
  final int id;
  final Map<String, dynamic> payload;
}

class GpsQueueDb {
  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final root = await getDatabasesPath();
    final path = '$root/zlatograd_tracker.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE gps_queue(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            payload TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> add(Map<String, dynamic> payload) async {
    final db = await _database();
    await db.insert('gps_queue', {
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'payload': jsonEncode(payload),
    });

    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM gps_queue'),
        ) ??
        0;
    if (count > 10000) {
      final extra = count - 10000;
      await db.rawDelete(
        'DELETE FROM gps_queue WHERE id IN (SELECT id FROM gps_queue ORDER BY id LIMIT ?)',
        [extra],
      );
    }
  }

  Future<List<QueuedPoint>> take(int limit) async {
    final db = await _database();
    final rows = await db.query('gps_queue', orderBy: 'id', limit: limit);
    return rows.map((row) {
      return QueuedPoint(
        row['id'] as int,
        Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map),
      );
    }).toList();
  }

  Future<int> count() async {
    final db = await _database();
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM gps_queue'),
        ) ??
        0;
  }

  Future<void> removeIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _database();
    final marks = List.filled(ids.length, '?').join(',');
    await db.delete('gps_queue', where: 'id IN ($marks)', whereArgs: ids);
  }

  Future<void> clear() async {
    final db = await _database();
    await db.delete('gps_queue');
  }
}
