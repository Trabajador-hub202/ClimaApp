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

  // Inicializa la base de datos local SQLite
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'skycast_favorites.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Creamos la tabla de favoritas asociando cada registro al correo del usuario
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            UNIQUE(name, email)
          )
        ''');
      },
    );
  }

  // Inserta una nueva ciudad favorita asociada a un correo en SQLite
  Future<int> insertFavorite(String cityName, String email) async {
    final db = await database;
    try {
      return await db.insert(
        'favorites',
        {'name': cityName, 'email': email},
        conflictAlgorithm: ConflictAlgorithm
            .ignore, // Ignora duplicados para ese mismo usuario
      );
    } catch (e) {
      print("Error al insertar favorita: $e");
      return -1;
    }
  }

  // Obtiene el listado de ciudades favoritas de un usuario específico
  Future<List<String>> getFavorites(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'email = ?',
      whereArgs: [email],
    );
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }

  // Elimina una ciudad de un usuario específico de la base de datos SQLite
  Future<int> deleteFavorite(String cityName, String email) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'name = ? AND email = ?',
      whereArgs: [cityName, email],
    );
  }
}
