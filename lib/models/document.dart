// lib/models/document.dart
import 'package:brief_ai/models/document_image.dart';

/// Document model representing a scanned/uploaded document
class Document {
  final int? id;
  final String title;
  final String categoryKey;
  final DateTime createdAt;
  final DateTime? deadline;
  final String statusKey;
  final String summary;
  final List<DocumentImage> images;

  const Document({
    this.id,
    required this.title,
    required this.categoryKey,
    required this.createdAt,
    this.deadline,
    required this.statusKey,
    this.summary = '',
    this.images = const [],
  });

  /// Check if document has a deadline
  bool get hasDeadline => deadline != null;

  /// Get formatted deadline string
  String? get formattedDeadline {
    if (deadline == null) return null;
    return '${deadline!.day}.${deadline!.month}.${deadline!.year}';
  }

  /// Get formatted creation date string
  String get formattedCreatedAt {
    return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
  }

  /// Get main image path (first image)
  String? get mainImagePath {
    return images.isNotEmpty ? images.first.imagePath : null;
  }

  /// Get all image paths
  List<String> get imagePaths => images.map((img) => img.imagePath).toList();

  /// Convert to JSON for database
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'categoryKey': categoryKey,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'statusKey': statusKey,
      'summary': summary,
    };
  }

  /// Create Document from JSON (from database)
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as int?,
      title: json['title'] as String,
      categoryKey: json['categoryKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      statusKey: json['statusKey'] as String,
      summary: json['summary'] as String? ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((img) => DocumentImage.fromMap(img as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create a copy of the document with optional field updates
  Document copyWith({
    int? id,
    String? title,
    String? categoryKey,
    DateTime? createdAt,
    DateTime? deadline,
    String? statusKey,
    String? summary,
    List<DocumentImage>? images,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryKey: categoryKey ?? this.categoryKey,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      statusKey: statusKey ?? this.statusKey,
      summary: summary ?? this.summary,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Status enum for document states
enum DocumentStatus {
  pending('pending', 'Pending'),
  inProgress('inProgress', 'In Progress'),
  done('done', 'Done'),
  archived('archived', 'Archived');

  final String key;
  final String displayName;

  const DocumentStatus(this.key, this.displayName);

  static DocumentStatus fromKey(String key) {
    return values.firstWhere(
      (status) => status.key == key,
      orElse: () => DocumentStatus.pending,
    );
  }
}
