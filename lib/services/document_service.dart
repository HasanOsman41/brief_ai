// lib/services/document_service.dart
import 'package:brief_ai/data/repositories/document_repository.dart';
import 'package:brief_ai/data/repositories/image_repository.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/models/document_image.dart';
import 'package:brief_ai/services/notification_service.dart';

/// DocumentService - Central service for document management
///
/// This service coordinates between repositories and provides a clean API
/// for the rest of the app to manage documents and their images.
class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  final DocumentRepository _documentRepo = DocumentRepository();
  final ImageRepository _imageRepo = ImageRepository();
  final NotificationService _notificationService = NotificationService();

  factory DocumentService() {
    return _instance;
  }

  DocumentService._internal();

  /// Get all documents with their images
  Future<List<Document>> getAllDocuments() async {
    try {
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
    String ocrText = '',
    List<String> imagePaths = const [],
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) async {
    try {
      final document = Document(
        title: title,
        categoryKey: categoryKey,
        createdAt: createdAt ?? DateTime.now(),
        deadline: deadline,
        statusKey: statusKey,
        summary: summary,
        ocrText: ocrText,
        reminder3DaysTime: reminder3DaysTime,
        reminder1DayTime: reminder1DayTime,
        reminder12HoursTime: reminder12HoursTime,
        reminderCustomTime: reminderCustomTime,
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
    String? ocrText,
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) async {
    try {
      final current = await getDocumentById(id);
      if (current == null) {
        throw Exception('Document with id $id not found');
      }
      final updated = Document(
        id: id,
        title: title ?? current.title,
        categoryKey: categoryKey ?? current.categoryKey,
        statusKey: statusKey ?? current.statusKey,
        summary: summary ?? current.summary,
        ocrText: ocrText ?? current.ocrText,
        createdAt: createdAt ?? current.createdAt,
        deadline: deadline ?? current.deadline,
        reminder3DaysTime: reminder3DaysTime,
        reminder1DayTime: reminder1DayTime,
        reminder12HoursTime: reminder12HoursTime,
        reminderCustomTime: reminderCustomTime,
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
      // Cancel all reminders for this document
      await _notificationService.cancelRemindersForDocument(id);

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
      return await _documentRepo.getCount();
    } catch (e) {
      print('❌ Error getting document count: $e');
      return 0;
    }
  }

  /// Get document count by category
  Future<int> getDocumentCountByCategory(String categoryKey) async {
    try {
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
      return await _imageRepo.getByDocumentId(documentId);
    } catch (e) {
      print('❌ Error fetching images for document $documentId: $e');
      return [];
    }
  }

  /// Delete image
  Future<void> deleteImage(int imageId) async {
    try {
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
      await _imageRepo.deleteByDocumentId(documentId);
      print('✅ All images deleted for document $documentId');
    } catch (e) {
      print('❌ Error deleting images for document $documentId: $e');
      rethrow;
    }
  }

  /// Schedule or update reminders for a document
  ///
  /// This method handles scheduling reminders based on the document's reminder settings.
  /// It generates predictable notification IDs based on documentId and reminder type.
  /// Reminder ID formula: documentId * 10 + offset
  /// - offset 0: 3-day reminder
  /// - offset 1: 1-day reminder
  /// - offset 2: 12-hour reminder
  /// - offset 3: custom reminder
  Future<void> scheduleReminders(
    int documentId,
    String title,
    DateTime deadline, {
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) async {
    try {
      final notificationService = NotificationService();

      // Format title for notification (max 50 chars)
      final notifyTitle = title.length > 50 ? title.substring(0, 50) : title;
      final body =
          'Deadline: ${deadline.day}.${deadline.month}.${deadline.year}';

      // Schedule reminders with predictable IDs
      if (reminder3DaysTime != null) {
        await notificationService.scheduleNotification(
          documentId * 10 + 0,
          notifyTitle,
          body,
          reminder3DaysTime,
          payload: 'doc_$documentId',
        );
      }
      if (reminder1DayTime != null) {
        await notificationService.scheduleNotification(
          documentId * 10 + 1,
          notifyTitle,
          body,
          reminder1DayTime,
          payload: 'doc_$documentId',
        );
      }
      if (reminder12HoursTime != null) {
        await notificationService.scheduleNotification(
          documentId * 10 + 2,
          notifyTitle,
          body,
          reminder12HoursTime,
          payload: 'doc_$documentId',
        );
      }
      if (reminderCustomTime != null) {
        await notificationService.scheduleNotification(
          documentId * 10 + 3,
          notifyTitle,
          body,
          reminderCustomTime,
          payload: 'doc_$documentId',
        );
      }

      print('✅ Reminders scheduled for document $documentId');
    } catch (e) {
      print('❌ Error scheduling reminders for document $documentId: $e');
      rethrow;
    }
  }

  /// Cancel all reminders for a document
  Future<void> cancelReminders(int documentId) async {
    try {
      await NotificationService().cancelRemindersForDocument(documentId);
      print('✅ Reminders cancelled for document $documentId');
    } catch (e) {
      print('❌ Error cancelling reminders for document $documentId: $e');
      rethrow;
    }
  }

  /// Create a new document with images and schedule reminders
  Future<int> createDocumentWithImagesAndReminders({
    required String title,
    required String categoryKey,
    required DateTime deadline,
    required String statusKey,
    required String summary,
    String ocrText = '',
    List<String> imagePaths = const [],
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) async {
    try {
      // Create the document
      final docId = await addDocument(
        title: title,
        categoryKey: categoryKey,
        deadline: deadline,
        statusKey: statusKey,
        summary: summary,
        ocrText: ocrText,
        imagePaths: imagePaths,
        reminder3DaysTime: reminder3DaysTime,
        reminder1DayTime: reminder1DayTime,
        reminder12HoursTime: reminder12HoursTime,
        reminderCustomTime: reminderCustomTime,
      );

      // Schedule reminders
      if (reminder3DaysTime != null ||
          reminder1DayTime != null ||
          reminder12HoursTime != null ||
          reminderCustomTime != null) {
        await scheduleReminders(
          docId,
          title,
          deadline,
          reminder3DaysTime: reminder3DaysTime,
          reminder1DayTime: reminder1DayTime,
          reminder12HoursTime: reminder12HoursTime,
          reminderCustomTime: reminderCustomTime,
        );
      }

      print('✅ Document created with images and reminders: $docId');
      return docId;
    } catch (e) {
      print('❌ Error creating document with images and reminders: $e');
      rethrow;
    }
  }

  /// Update existing document, replace images, and reschedule reminders
  Future<void> updateDocumentWithImagesAndReminders(
    int id, {
    required String title,
    required String categoryKey,
    required DateTime deadline,
    required String statusKey,
    required String summary,
    String ocrText = '',
    List<String> imagePaths = const [],
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) async {
    try {
      // Cancel old reminders first
      await cancelReminders(id);

      // Update document info
      await updateDocument(
        id,
        title: title,
        categoryKey: categoryKey,
        deadline: deadline,
        statusKey: statusKey,
        summary: summary,
        ocrText: ocrText,
        reminder3DaysTime: reminder3DaysTime,
        reminder1DayTime: reminder1DayTime,
        reminder12HoursTime: reminder12HoursTime,
        reminderCustomTime: reminderCustomTime,
      );

      // Replace images: delete all old ones and add new ones
      await deleteAllImages(id);
      if (imagePaths.isNotEmpty) {
        await addImagesToDocument(id, imagePaths);
      }

      // Schedule new reminders
      if (reminder3DaysTime != null ||
          reminder1DayTime != null ||
          reminder12HoursTime != null ||
          reminderCustomTime != null) {
        await scheduleReminders(
          id,
          title,
          deadline,
          reminder3DaysTime: reminder3DaysTime,
          reminder1DayTime: reminder1DayTime,
          reminder12HoursTime: reminder12HoursTime,
          reminderCustomTime: reminderCustomTime,
        );
      }

      print('✅ Document updated with images and reminders: $id');
    } catch (e) {
      print('❌ Error updating document with images and reminders: $e');
      rethrow;
    }
  }

  /// Mark a document as done and cancel all associated reminders
  Future<void> markDocumentAsDone(int id) async {
    try {
      // Cancel all reminders for this document
      await cancelReminders(id);

      // Update document status to 'done'
      await updateDocumentStatus(id, 'done');

      print('✅ Document marked as done with id: $id');
    } catch (e) {
      print('❌ Error marking document as done with id $id: $e');
      rethrow;
    }
  }
}
