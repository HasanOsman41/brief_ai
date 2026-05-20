import 'package:bloc/bloc.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:equatable/equatable.dart';

part 'document_state.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final DocumentService _documentService = DocumentService();

  DocumentCubit() : super(DocumentInitial());

  Future<void> loadDocuments() async {
    emit(DocumentLoading());
    try {
      final documents = await _documentService.getAllDocuments();
      emit(DocumentLoaded(documents));
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> addDocument({
    required String title,
    required String subCategoryKey,
    required String mainCategoryKey,
    DateTime? createdAt,
    DateTime? deadline,
    required String statusKey,
    required String summaryKey,
    String ocrText = '',
    List<String> imagePaths = const [],
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) async {
    try {
      final currentState = state;
      
      final docId = await _documentService.createDocumentWithImagesAndReminders(
        title: title,
        subCategoryKey: subCategoryKey,
        mainCategoryKey: mainCategoryKey,
        deadline: deadline,
        statusKey: statusKey,
        summaryKey: summaryKey,
        ocrText: ocrText,
        imagePaths: imagePaths,
        reminder3DaysTime: reminder3DaysTime,
        reminder1DayTime: reminder1DayTime,
        reminder12HoursTime: reminder12HoursTime,
        reminderCustomTime: reminderCustomTime,
      );

      final newDocument = await _documentService.getDocumentById(docId);
      
      if (newDocument != null && currentState is DocumentLoaded) {
        final updatedList = [newDocument, ...currentState.documents];
        emit(DocumentLoaded(updatedList));
      } else if (currentState is DocumentLoaded) {
        await loadDocuments();
      }
    } catch (e) {
      emit(DocumentError(e.toString()));
      await loadDocuments();
    }
  }

  Future<void> updateDocument({
    required int id,
    String? title,
    String? subCategoryKey,
    String? mainCategoryKey,
    DateTime? createdAt,
    DateTime? deadline,
    String? statusKey,
    String? summaryKey,
    String? ocrText,
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) async {
    try {
      final currentState = state;
      
      final updatedDocument = await _documentService.updateDocument(
        id,
        title: title,
        subCategoryKey: subCategoryKey,
        mainCategoryKey: mainCategoryKey,
        createdAt: createdAt,
        deadline: deadline,
        statusKey: statusKey,
        summaryKey: summaryKey,
        ocrText: ocrText,
        reminder3DaysTime: reminder3DaysTime,
        reminder1DayTime: reminder1DayTime,
        reminder12HoursTime: reminder12HoursTime,
        reminderCustomTime: reminderCustomTime,
      );

      if (currentState is DocumentLoaded) {
        final updatedList = currentState.documents.map((doc) {
          return doc.id == id ? updatedDocument : doc;
        }).toList();
        emit(DocumentLoaded(updatedList));
      }
    } catch (e) {
      emit(DocumentError(e.toString()));
      await loadDocuments();
    }
  }

  Future<void> markDocumentAsDone(int id) async {
    try {
      final currentState = state;
      
      await _documentService.markDocumentAsDone(id);

      if (currentState is DocumentLoaded) {
        final updatedList = currentState.documents.map((doc) {
          if (doc.id == id) {
            return doc.copyWith(statusKey: 'done');
          }
          return doc;
        }).toList();
        emit(DocumentLoaded(updatedList));
      }
    } catch (e) {
      emit(DocumentError(e.toString()));
      await loadDocuments();
    }
  }

  Future<void> reopenDocument(int id) async {
    try {
      final currentState = state;
      
      await _documentService.reopenDocument(id);

      if (currentState is DocumentLoaded) {
        final updatedList = currentState.documents.map((doc) {
          if (doc.id == id) {
            return doc.copyWith(statusKey: 'pending');
          }
          return doc;
        }).toList();
        emit(DocumentLoaded(updatedList));
      }
    } catch (e) {
      emit(DocumentError(e.toString()));
      await loadDocuments();
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      final currentState = state;
      
      await _documentService.deleteDocument(id);

      if (currentState is DocumentLoaded) {
        final updatedList = currentState.documents
            .where((doc) => doc.id != id)
            .toList();
        emit(DocumentLoaded(updatedList));
      }
    } catch (e) {
      emit(DocumentError(e.toString()));
      await loadDocuments();
    }
  }

  Future<void> refreshFromDatabase() async {
    await loadDocuments();
  }
  // Add to document_cubit.dart
Future<List<Document>> searchDocuments(String query) async {
  emit(DocumentLoading());
  try {
    final documents = await _documentService.searchDocuments(query);
    emit(DocumentLoaded(documents));
    return documents;
  } catch (e) {
    emit(DocumentError(e.toString()));
    return [];
  }
}
}