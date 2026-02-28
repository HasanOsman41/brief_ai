import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

/// DatabaseHelper - Singleton for managing database connection and schema
///
/// This helper is responsible for:
/// - Creating and managing the SQLite database connection
/// - Creating and maintaining database tables and schema
/// - Providing access to the database instance for repositories
///
/// All CRUD operations are delegated to specific repositories:
/// - DocumentRepository (document operations)
/// - ImageRepository (image operations)
/// - Add more repositories as new tables are added

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  /// Get or create the database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database and create tables
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'brief_ai.db');

    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        categoryKey TEXT NOT NULL,
        date TEXT NOT NULL,
        deadline TEXT,
        statusKey TEXT NOT NULL,
        hasDeadline INTEGER NOT NULL,
        summary TEXT DEFAULT '',
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Images table - store multiple images per document
    await db.execute('''
      CREATE TABLE images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for efficient queries
    await db.execute('''
      CREATE INDEX idx_documents_category ON documents(categoryKey)
    ''');

    await db.execute('''
      CREATE INDEX idx_documents_status ON documents(statusKey)
    ''');

    await db.execute('''
      CREATE INDEX idx_images_documentId ON images(documentId)
    ''');
  }

  /// Close the database connection (call during app shutdown if needed)
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
