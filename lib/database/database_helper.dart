import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'mova.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
        )
     ''');
      },
    );
  }

  Future<int> insertUser(String name, String email, String password) async {
  final db = await database;

  return await db.insert(
    'users',
    {
      'name': name,
      'email' : email,
      'password' : password,
    },
  );
}

Future<Map<String,dynamic>?> loginUser(
  String email,
  String password,
)async {
  final db = await database;

  final result = await db.query(
    'users',
    where: 'email = ? AND password = ?',
    whereArgs: [email, password],
    limit: 1,
  );

  if(result.isNotEmpty){
    return result.first;
  }
}

Future<List<Map<String,dynamic>>> getUsers() async {
  final db = await database;

  return await db.query('users');
}
}


