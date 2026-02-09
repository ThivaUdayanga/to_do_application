import 'dart:convert';
import 'package:crypto/crypto.dart'; // for hashing passwords
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'model/user_model.dart';
import 'model/task_model.dart';

class DBHelper {
  static Database? _database; //singleton pattern

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'todo_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Task table
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ownerId TEXT NOT NULL, 
            title TEXT, 
            description TEXT, 
            createdAt TEXT, 
            dueDate TEXT, 
            isCompleted INTEGER
          )
        ''');
        // User table
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            firstName TEXT, 
            lastName TEXT, 
            email TEXT, 
            password TEXT
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        // ✅ If upgrading from older DB that didn't have ownerId
        if (oldVersion < 2) {
          // Add ownerId column if it doesn't exist
          await db.execute("ALTER TABLE tasks ADD COLUMN ownerId TEXT");

          // Optional: set a default value for existing rows (otherwise they will be null)
          // If you want old tasks to belong to someone, put a value here.
          await db.execute(
            "UPDATE tasks SET ownerId = 'unknown' WHERE ownerId IS NULL",
          );
        }
      },
    );
  }

  // --- Password Hashing Logic ---
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Password eka bytes walata harawanawa
    var digest = sha256.convert(bytes); // SHA-256 algorithm eka use karanawa
    return digest.toString();
  }

  // --- Auth Operations ---

  // User Registration
  static Future<int> registerUser(User user) async {
    final db = await database;
    // Password eka hash karala thamai database ekata danne
    User hashedUser = User(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      password: _hashPassword(user.password),
    );
    return await db.insert('users', hashedUser.toMap());
  }

  // User Login
  static Future<User?> loginUser(String email, String password) async {
    final db = await database;
    String hashedInputPassword = _hashPassword(password);

    // Email saha hashed password eka match wenawada balanawa
    List<Map<String, dynamic>> res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedInputPassword],
    );

    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null; // Login failed nam null return karanawa
  }

  // --- Task Operations ---

  // 1. Task ekak add kirima (Create)
  static Future<int> insertTask(Task task) async {
    final db = await database;

    // FIX: Remove the 'id' field when inserting (SQLite auto-generates it)
    Map<String, dynamic> taskMap = task.toMap();
    taskMap.remove('id'); // Remove null id to avoid SQLite error

    return await db.insert(
      'tasks',
      taskMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //get task by ownerID
  static Future<List<Task>> getTasksByOwner(String ownerId) async {
    final db = await database;
    final res = await db.query(
      'tasks',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'id DESC',
    );

    return res.map((e) => Task.fromMap(e)).toList();
  }

  // 2. Okkoma tasks list ekak widiyata ganna (Read)
  static Future<List<Task>> getTasks() async {
    final db = await database;
    // 'id' eken order karala data tika gannawa
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // 3. Task ekak update kirima (Update)
  static Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // 4. Task ekak delete kirima (Delete)
  static Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
