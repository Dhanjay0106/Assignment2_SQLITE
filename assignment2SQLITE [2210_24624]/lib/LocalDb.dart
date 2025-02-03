import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  // Singleton instance
  static final LocalDatabase instance = LocalDatabase._internal();

  // Database instance
  static Database? _database;

  // Private named constructor
  LocalDatabase._internal();

  // Getter for database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rooms.db');
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create the rooms table
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        price REAL NOT NULL,
        availability INTEGER NOT NULL
      )
    ''');
  }

  // Add a room with auto-incrementing ID
  Future<int> addRoom(String roomType, double price, bool availability) async {
    final db = await instance.database;
    return await db.insert('rooms', {
      'type': roomType,
      'price': price,
      'availability': availability ? 1 : 0,
    });
  }

  // Get all rooms
  Future<List<Map<String, dynamic>>> getAllRooms() async {
    final db = await instance.database;
    return await db.query('rooms');
  }

  // Update room details
  Future<int> updateRoom(int id, Map<String, dynamic> data) async {
    final db = await instance.database;

    return await db.update(
      'rooms',
      {
        'type': data['type'] ?? "", // Ensure null safety
        'price': data['price'] ?? 0.0,
        'availability': (data['availability'] ?? false) ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a room
  Future<int> deleteRoom(int id) async {
    final db = await instance.database;
    return await db.delete(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}