// lib/models/document_image.dart
/// DocumentImage model for storing multiple images per document
class DocumentImage {
  final int? id;
  final int documentId;
  final String imagePath;
  final DateTime createdAt;

  const DocumentImage({
    this.id,
    required this.documentId,
    required this.imagePath,
    required this.createdAt,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'documentId': documentId,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory DocumentImage.fromMap(Map<String, dynamic> map) {
    return DocumentImage(
      id: map['id'] as int?,
      documentId: map['documentId'] as int,
      imagePath: map['imagePath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Copy with new values
  DocumentImage copyWith({
    int? id,
    int? documentId,
    String? imagePath,
    int? order,
    DateTime? createdAt,
  }) {
    return DocumentImage(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentImage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
