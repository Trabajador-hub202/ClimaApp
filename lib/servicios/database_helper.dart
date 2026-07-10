import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa la base de datos local sqlite
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'skycast_favorites.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Creamos la tabla de favoritas
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
          )
        ''');
      },
    );
  }

  // Inserta una nueva ciudad favorita en SQLite
  Future<int> insertFavorite(String cityName) async {
    final db = await database;
    try {
      return await db.insert(
        'favorites',
        {'name': cityName},
        conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora duplicados
      );
    } catch (e) {
      print("Error al insertar: $e");
      return -1;
    }
  }

  // Obtiene el listado de ciudades favoritas registradas
  Future<List<String>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }

  // Elimina una ciudad de la base de datos SQLite
  Future<int> deleteFavorite(String cityName) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'name = ?',
      whereArgs: [cityName],
    );
  }
}
