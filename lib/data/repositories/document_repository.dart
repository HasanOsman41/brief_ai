// lib/data/repositories/document_repository.dart
import 'package:brief_ai/data/local/database_helper.dart';
import 'package:brief_ai/models/document.dart';

class DocumentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert a single document
  Future<int> insert(Document document) async {
    final db = await _dbHelper.database;
    return await db.insert('documents', document.toJson());
  }

  /// Insert multiple documents
  Future<List<int>> insertMultiple(List<Document> documents) async {
    final db = await _dbHelper.database;
    final List<int> ids = [];

    await db.transaction((txn) async {
      for (final doc in documents) {
        final id = await txn.insert('documents', doc.toJson());
        ids.add(id);
      }
    });

    return ids;
  }

  /// Get all documents (without images)
  Future<List<Document>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.query('documents', orderBy: 'createdAt DESC');

    return result.map((json) => Document.fromJson(json)).toList();
  }

  /// Get document by ID (without images)
  Future<Document?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result.isNotEmpty ? Document.fromJson(result.first) : null;
  }

  /// Update document
  Future<int> update(Document document) async {
    if (document.id == null) {
      throw Exception('Cannot update document without ID');
    }

    final db = await _dbHelper.database;
    final json = document.toJson();
    json['updatedAt'] = DateTime.now().toIso8601String();

    return await db.update(
      'documents',
      json,
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  /// Update document status
  Future<int> updateStatus(int id, String statusKey) async {
    final db = await _dbHelper.database;
    return await db.update(
      'documents',
      {'statusKey': statusKey, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete document
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  /// Search documents by title
  Future<List<Document>> search(String query) async {
    final db = await _dbHelper.database;
    final lowerQuery = '%${query.toLowerCase()}%';

    final result = await db.query(
      'documents',
      where: 'LOWER(title) LIKE ?',
      whereArgs: [lowerQuery],
      orderBy: 'createdAt DESC',
    );

    return result.map((json) => Document.fromJson(json)).toList();
  }

  /// Get documents by category
  Future<List<Document>> getByCategory(String categoryKey) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'documents',
      where: 'categoryKey = ?',
      whereArgs: [categoryKey],
      orderBy: 'createdAt DESC',
    );

    return result.map((json) => Document.fromJson(json)).toList();
  }

  /// Get documents by status
  Future<List<Document>> getByStatus(String statusKey) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'documents',
      where: 'statusKey = ?',
      whereArgs: [statusKey],
      orderBy: 'createdAt DESC',
    );

    return result.map((json) => Document.fromJson(json)).toList();
  }

  /// Get upcoming deadlines
  Future<List<Document>> getUpcomingDeadlines({int days = 30}) async {
    final db = await _dbHelper.database;
    final futureDate = DateTime.now()
        .add(Duration(days: days))
        .toIso8601String();

    final result = await db.query(
      'documents',
      where: 'deadline IS NOT NULL AND deadline <= ?',
      whereArgs: [futureDate],
      orderBy: 'deadline ASC',
    );

    return result.map((json) => Document.fromJson(json)).toList();
  }

  /// Get total document count
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM documents');
    return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
  }

  /// Get document count by category
  Future<int> getCountByCategory(String categoryKey) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM documents WHERE categoryKey = ?',
      [categoryKey],
    );
    return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
  }

  /// Delete all documents (for testing/reset)
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('documents');
  }
}
