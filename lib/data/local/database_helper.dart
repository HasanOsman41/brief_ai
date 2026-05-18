// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'brief_ai.db');

    return await openDatabase(dbPath, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subCategoryKey TEXT NOT NULL,
        mainCategoryKey TEXT NOT NULL,
        date TEXT NOT NULL,
        deadline TEXT,
        statusKey TEXT NOT NULL,
        hasDeadline INTEGER NOT NULL,
        summaryKey TEXT DEFAULT 'summary_unknown_document',
        ocrText TEXT DEFAULT '',
        reminder3DaysTime TEXT,
        reminder1DayTime TEXT,
        reminder12HoursTime TEXT,
        reminderCustomTime TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Images table - store relative paths to images directory
    await db.execute('''
      CREATE TABLE images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_documents_category ON documents(mainCategoryKey)',
    );
    await db.execute(
      'CREATE INDEX idx_documents_status ON documents(statusKey)',
    );
    await db.execute(
      'CREATE INDEX idx_images_documentId ON images(documentId)',
    );
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Get the images directory path
  Future<String> getImagesDirectoryPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final imagesDir = join(documentsDirectory.path, 'images');
    await Directory(imagesDir).create(recursive: true);
    return imagesDir;
  }

  /// Get the database file path
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'brief_ai.db');
  }

  /// Save an image file and return the stored path
  Future<String> saveImageFile(File imageFile, int documentId) async {
    final imagesDir = await getImagesDirectoryPath();
    final fileName =
        'doc_${documentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = join(imagesDir, fileName);

    await imageFile.copy(savedPath);
    return savedPath;
  }
}
