// lib/data/repositories/image_repository.dart
import 'package:brief_ai/data/local/database_helper.dart';
import 'package:brief_ai/models/document_image.dart';
import 'package:sqflite/sqflite.dart';

class ImageRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert a single image
  Future<int> insert(int documentId, String imagePath) async {
    final db = await _dbHelper.database;
    final image = DocumentImage(
      documentId: documentId,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    return await db.insert('images', image.toMap());
  }

  /// Insert multiple images
  Future<List<int>> insertMultiple(
    int documentId,
    List<String> imagePaths,
  ) async {
    final db = await _dbHelper.database;
    final List<int> ids = [];

    await db.transaction((txn) async {
      for (int i = 0; i < imagePaths.length; i++) {
        final image = DocumentImage(
          documentId: documentId,
          imagePath: imagePaths[i],
          createdAt: DateTime.now(),
        );
        final id = await txn.insert('images', image.toMap());
        ids.add(id);
      }
    });

    return ids;
  }

  /// Get all images for a document
  Future<List<DocumentImage>?> getByDocumentId(int documentId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'images',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'id ASC',
    );

    return result.map((json) => DocumentImage.fromMap(json)).toList();
  }

  /// Get image by ID
  Future<DocumentImage?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('images', where: 'id = ?', whereArgs: [id]);

    return result.isNotEmpty ? DocumentImage.fromMap(result.first) : null;
  }

  /// Update image order
  Future<int> updateOrder(int id, int newOrder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'images',
      {'order': newOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete image
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('images', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all images for a document
  Future<int> deleteByDocumentId(int documentId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'images',
      where: 'documentId = ?',
      whereArgs: [documentId],
    );
  }

  /// Get image count for a document
  Future<int> getCountByDocumentId(int documentId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM images WHERE documentId = ?',
      [documentId],
    );
    return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
  }

  /// Reorder images (batch update)
  Future<void> reorderImages(int documentId, List<int> imageIds) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      for (int i = 0; i < imageIds.length; i++) {
        await txn.update(
          'images',
          {'order': i},
          where: 'id = ? AND documentId = ?',
          whereArgs: [imageIds[i], documentId],
        );
      }
    });
  }
}
