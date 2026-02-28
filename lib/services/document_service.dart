// lib/services/document_service.dart
import 'package:brief_ai/data/repositories/document_repository.dart';
import 'package:brief_ai/data/repositories/image_repository.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/models/document_image.dart';

/// DocumentService - Central service for document management
///
/// This service coordinates between repositories and provides a clean API
/// for the rest of the app to manage documents and their images.
class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  final DocumentRepository _documentRepo = DocumentRepository();
  final ImageRepository _imageRepo = ImageRepository();
  bool _isInitialized = false;

  factory DocumentService() {
    return _instance;
  }

  DocumentService._internal();

  /// Initialize the service and seed initial data if needed
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final count = await _documentRepo.getCount();
      if (count == 0) {
        await _seedInitialData();
      }
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing DocumentService: $e');
      rethrow;
    }
  }

  /// Seed initial documents
  Future<void> _seedInitialData() async {
    try {
      final now = DateTime.now();

      final initialDocuments = [
        Document(
          title: 'Mietvertrag Wohnung',
          categoryKey: 'rent',
          createdAt: DateTime(now.year, now.month, now.day - 5),
          deadline: now.add(const Duration(days: 2)),
          statusKey: 'pending',
          summary: 'Mietvertrag für die neue Wohnung in Berlin',
        ),
        Document(
          title: 'GEZ Befreiung',
          categoryKey: 'other',
          createdAt: DateTime(now.year, now.month, now.day - 10),
          deadline: now.add(const Duration(days: 5)),
          statusKey: 'done',
          summary: 'Befreiung von Rundfunkgebühren',
        ),
        Document(
          title: 'Stromrechnung Januar',
          categoryKey: 'bills',
          createdAt: DateTime(now.year, now.month, now.day - 15),
          deadline: now.add(const Duration(days: 12)),
          statusKey: 'pending',
          summary: 'Stromrechnung für Januar 2024',
        ),
        Document(
          title: 'Krankenkassenbescheid',
          categoryKey: 'krankenkasse',
          createdAt: DateTime(now.year, now.month, now.day - 20),
          deadline: null,
          statusKey: 'pending',
          summary: 'Bescheid über Beitragsanpassung',
        ),
      ];

      // Insert documents and their images
      final imagesList = [
        ['1.jpeg'],
        ['2.jpeg'],
        ['3.jpeg'],
        ['4.jpeg'],
      ];

      for (int i = 0; i < initialDocuments.length; i++) {
        final docId = await _documentRepo.insert(initialDocuments[i]);

        // Add default images
        if (imagesList[i].isNotEmpty) {
          await _imageRepo.insertMultiple(docId, imagesList[i]);
        }
      }

      print('✅ Initial data seeded successfully');
    } catch (e) {
      print('❌ Error seeding initial data: $e');
      rethrow;
    }
  }

  /// Get all documents with their images
  Future<List<Document>> getAllDocuments() async {
    try {
      await initialize();
      final documents = await _documentRepo.getAll();

      // Fetch images for each document
      final result = <Document>[];
      for (final doc in documents) {
        if (doc.id != null) {
          final images = await _imageRepo.getByDocumentId(doc.id!);
          result.add(doc.copyWith(images: images));
        }
      }

      return result;
    } catch (e) {
      print('❌ Error fetching all documents: $e');
      return [];
    }
  }

  /// Get document by ID with its images
  Future<Document?> getDocumentById(int id) async {
    try {
      await initialize();
      final document = await _documentRepo.getById(id);

      if (document != null && document.id != null) {
        final images = await _imageRepo.getByDocumentId(document.id!);
        return document.copyWith(images: images);
      }

      return document;
    } catch (e) {
      print('❌ Error fetching document with id $id: $e');
      return null;
    }
  }

  /// Add a new document with images
  Future<int> addDocument({
    required String title,
    required String categoryKey,
    DateTime? createdAt,
    DateTime? deadline,
    required String statusKey,
    required String summary,
    List<String> imagePaths = const [],
  }) async {
    try {
      await initialize();

      final document = Document(
        title: title,
        categoryKey: categoryKey,
        createdAt: createdAt ?? DateTime.now(),
        deadline: deadline,
        statusKey: statusKey,
        summary: summary,
      );

      final docId = await _documentRepo.insert(document);

      // Add images if provided
      if (imagePaths.isNotEmpty) {
        await _imageRepo.insertMultiple(docId, imagePaths);
      }

      print('✅ Document added successfully with id: $docId');
      return docId;
    } catch (e) {
      print('❌ Error adding document: $e');
      rethrow;
    }
  }

  /// Update document info
  Future<Document> updateDocument(
    int id, {
    String? title,
    String? categoryKey,
    DateTime? createdAt,
    DateTime? deadline,
    String? statusKey,
    String? summary,
  }) async {
    try {
      await initialize();

      final current = await getDocumentById(id);
      if (current == null) {
        throw Exception('Document with id $id not found');
      }

      final updated = current.copyWith(
        title: title,
        categoryKey: categoryKey,
        createdAt: createdAt,
        deadline: deadline,
        statusKey: statusKey,
        summary: summary,
      );

      await _documentRepo.update(updated);
      print('✅ Document updated successfully with id: $id');

      // Return the updated document with images
      return updated.copyWith(images: current.images);
    } catch (e) {
      print('❌ Error updating document with id $id: $e');
      rethrow;
    }
  }

  /// Update document status
  Future<void> updateDocumentStatus(int id, String statusKey) async {
    try {
      await initialize();
      await _documentRepo.updateStatus(id, statusKey);
      print('✅ Document status updated to $statusKey for id: $id');
    } catch (e) {
      print('❌ Error updating document status for id $id: $e');
      rethrow;
    }
  }

  /// Delete document (and its images via cascade)
  Future<void> deleteDocument(int id) async {
    try {
      await initialize();
      await _documentRepo.delete(id);
      print('✅ Document deleted successfully with id: $id');
    } catch (e) {
      print('❌ Error deleting document with id $id: $e');
      rethrow;
    }
  }

  /// Search documents
  Future<List<Document>> searchDocuments(String query) async {
    try {
      await initialize();
      final documents = await _documentRepo.search(query);

      // Fetch images for each document
      final result = <Document>[];
      for (final doc in documents) {
        if (doc.id != null) {
          final images = await _imageRepo.getByDocumentId(doc.id!);
          result.add(doc.copyWith(images: images));
        }
      }

      print('✅ Search completed: found ${result.length} documents');
      return result;
    } catch (e) {
      print('❌ Error searching documents with query "$query": $e');
      return [];
    }
  }

  /// Get documents by category
  Future<List<Document>> getDocumentsByCategory(String categoryKey) async {
    try {
      await initialize();
      final documents = await _documentRepo.getByCategory(categoryKey);

      // Fetch images for each document
      final result = <Document>[];
      for (final doc in documents) {
        if (doc.id != null) {
          final images = await _imageRepo.getByDocumentId(doc.id!);
          result.add(doc.copyWith(images: images));
        }
      }

      return result;
    } catch (e) {
      print('❌ Error fetching documents by category $categoryKey: $e');
      return [];
    }
  }

  /// Get documents by status
  Future<List<Document>> getDocumentsByStatus(String statusKey) async {
    try {
      await initialize();
      final documents = await _documentRepo.getByStatus(statusKey);

      // Fetch images for each document
      final result = <Document>[];
      for (final doc in documents) {
        if (doc.id != null) {
          final images = await _imageRepo.getByDocumentId(doc.id!);
          result.add(doc.copyWith(images: images));
        }
      }

      return result;
    } catch (e) {
      print('❌ Error fetching documents by status $statusKey: $e');
      return [];
    }
  }

  /// Get upcoming deadlines
  Future<List<Document>> getUpcomingDeadlines({int days = 30}) async {
    try {
      await initialize();
      final documents = await _documentRepo.getUpcomingDeadlines(days: days);

      // Fetch images for each document
      final result = <Document>[];
      for (final doc in documents) {
        if (doc.id != null) {
          final images = await _imageRepo.getByDocumentId(doc.id!);
          result.add(doc.copyWith(images: images));
        }
      }

      return result;
    } catch (e) {
      print('❌ Error fetching upcoming deadlines for $days days: $e');
      return [];
    }
  }

  /// Get document count
  Future<int> getDocumentCount() async {
    try {
      await initialize();
      return await _documentRepo.getCount();
    } catch (e) {
      print('❌ Error getting document count: $e');
      return 0;
    }
  }

  /// Get document count by category
  Future<int> getDocumentCountByCategory(String categoryKey) async {
    try {
      await initialize();
      return await _documentRepo.getCountByCategory(categoryKey);
    } catch (e) {
      print('❌ Error getting document count for category $categoryKey: $e');
      return 0;
    }
  }

  /// Add image to document
  Future<DocumentImage> addImageToDocument(
    int documentId,
    String imagePath,
  ) async {
    try {
      await initialize();
      final imageId = await _imageRepo.insert(documentId, imagePath);

      final image = DocumentImage(
        id: imageId,
        documentId: documentId,
        imagePath: imagePath,
        createdAt: DateTime.now(),
      );

      print('✅ Image added successfully to document $documentId');
      return image;
    } catch (e) {
      print('❌ Error adding image to document $documentId: $e');
      rethrow;
    }
  }

  /// Add multiple images to document
  Future<List<DocumentImage>> addImagesToDocument(
    int documentId,
    List<String> imagePaths,
  ) async {
    try {
      await initialize();

      // Get current image count for this document
      final existingImages = await _imageRepo.getByDocumentId(documentId);
      final startOrder = existingImages?.length ?? 0;

      final ids = await _imageRepo.insertMultiple(documentId, imagePaths);

      final images = <DocumentImage>[];
      for (int i = 0; i < ids.length; i++) {
        images.add(
          DocumentImage(
            id: ids[i],
            documentId: documentId,
            imagePath: imagePaths[i],
            createdAt: DateTime.now(),
          ),
        );
      }

      print(
        '✅ ${images.length} images added successfully to document $documentId',
      );
      return images;
    } catch (e) {
      print('❌ Error adding multiple images to document $documentId: $e');
      rethrow;
    }
  }

  /// Get images for document
  Future<List<DocumentImage>?> getDocumentImages(int documentId) async {
    try {
      await initialize();
      return await _imageRepo.getByDocumentId(documentId);
    } catch (e) {
      print('❌ Error fetching images for document $documentId: $e');
      return [];
    }
  }

  /// Delete image
  Future<void> deleteImage(int imageId) async {
    try {
      await initialize();
      await _imageRepo.delete(imageId);
      print('✅ Image deleted successfully with id: $imageId');
    } catch (e) {
      print('❌ Error deleting image with id $imageId: $e');
      rethrow;
    }
  }

  /// Update image order
  Future<void> updateImageOrder(int imageId, int newOrder) async {
    try {
      await initialize();
      await _imageRepo.updateOrder(imageId, newOrder);
      print('✅ Image order updated for id: $imageId');
    } catch (e) {
      print('❌ Error updating image order for id $imageId: $e');
      rethrow;
    }
  }

  /// Reorder images for a document
  Future<void> reorderImages(int documentId, List<int> imageIds) async {
    try {
      await initialize();
      await _imageRepo.reorderImages(documentId, imageIds);
      print('✅ Images reordered for document $documentId');
    } catch (e) {
      print('❌ Error reordering images for document $documentId: $e');
      rethrow;
    }
  }

  /// Delete all images for a document
  Future<void> deleteAllImages(int documentId) async {
    try {
      await initialize();
      await _imageRepo.deleteByDocumentId(documentId);
      print('✅ All images deleted for document $documentId');
    } catch (e) {
      print('❌ Error deleting images for document $documentId: $e');
      rethrow;
    }
  }
}
