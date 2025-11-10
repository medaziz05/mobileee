import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zenlife.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Version incrémentée
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phoneNumber TEXT,
        profileImage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        isActive INTEGER NOT NULL,
        lastLogin TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE password_resets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        code TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajout de la colonne phoneNumber si elle n'existe pas
      await db.execute('ALTER TABLE users ADD COLUMN phoneNumber TEXT');
    }
  }

  // ===== USERS CRUD =====
  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== SESSIONS =====
  Future<int> createSession(int userId) async {
    final db = await instance.database;
    await db.delete('sessions', where: 'userId = ?', whereArgs: [userId]);
    return await db.insert('sessions', {
      'userId': userId,
      'isActive': 1,
      'lastLogin': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await instance.database;
    final result = await db.query(
      'sessions',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteSession(int userId) async {
    final db = await instance.database;
    return await db.delete(
      'sessions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ===== PASSWORD RESETS =====
  Future<int> createPasswordReset(String email, String code) async {
    final db = await instance.database;
    await db.delete('password_resets', where: 'email = ?', whereArgs: [email]);
    return await db.insert('password_resets', {
      'email': email,
      'code': code,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(Duration(minutes: 15)).toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getPasswordReset(String email, String code) async {
    final db = await instance.database;
    final result = await db.query(
      'password_resets',
      where: 'email = ? AND code = ?',
      whereArgs: [email, code],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deletePasswordReset(String email) async {
    final db = await instance.database;
    return await db.delete(
      'password_resets',
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}