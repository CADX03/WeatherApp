import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Class to handle the database for cities
class CityDatabase {
  static final CityDatabase _instance = CityDatabase._internal();
  factory CityDatabase() => _instance;

  static Database? _database;

  CityDatabase._internal();

  // Method to get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    return _database = await _initDatabase();
  }

  // Method to initialize the database
  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'cities.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE cities(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE)',
        );
      },
    );
  }

  // Method to retrieve all saved cities from the database
  Future<List<String>> getCities() async {
    final db = await database;
    final result = await db.query('cities');
    return result.map((e) => e['name'] as String).toList();
  }

  // Method to add cities to the database
  Future<void> addCity(String city) async {
    final db = await database;
    await db.insert('cities', {'name': city}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Method to remove cities from the database
  Future<void> removeCity(String city) async {
    final db = await database;
    await db.delete('cities', where: 'name = ?', whereArgs: [city]);
  }
}
