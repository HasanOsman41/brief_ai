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
  final String ocrText;
  final List<DocumentImage> images;
  final DateTime? reminder3DaysTime;
  final DateTime? reminder1DayTime;
  final DateTime? reminder12HoursTime;
  final DateTime? reminderCustomTime;

  const Document({
    this.id,
    required this.title,
    required this.categoryKey,
    required this.createdAt,
    this.deadline,
    required this.statusKey,
    this.summary = '',
    this.ocrText = '',
    this.images = const [],
    this.reminder3DaysTime,
    this.reminder1DayTime,
    this.reminder12HoursTime,
    this.reminderCustomTime,
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
      'date': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'statusKey': statusKey,
      'hasDeadline': hasDeadline ? 1 : 0,
      'summary': summary,
      'ocrText': ocrText,
      'reminder3DaysTime': reminder3DaysTime?.toIso8601String(),
      'reminder1DayTime': reminder1DayTime?.toIso8601String(),
      'reminder12HoursTime': reminder12HoursTime?.toIso8601String(),
      'reminderCustomTime': reminderCustomTime?.toIso8601String(),
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
      ocrText: json['ocrText'] as String? ?? '',
      reminder3DaysTime: json['reminder3DaysTime'] != null
          ? DateTime.parse(json['reminder3DaysTime'] as String)
          : null,
      reminder1DayTime: json['reminder1DayTime'] != null
          ? DateTime.parse(json['reminder1DayTime'] as String)
          : null,
      reminder12HoursTime: json['reminder12HoursTime'] != null
          ? DateTime.parse(json['reminder12HoursTime'] as String)
          : null,
      reminderCustomTime: json['reminderCustomTime'] != null
          ? DateTime.parse(json['reminderCustomTime'] as String)
          : null,
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
    String? ocrText,
    List<DocumentImage>? images,
    DateTime? reminder3DaysTime,
    DateTime? reminder1DayTime,
    DateTime? reminder12HoursTime,
    DateTime? reminderCustomTime,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryKey: categoryKey ?? this.categoryKey,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      statusKey: statusKey ?? this.statusKey,
      summary: summary ?? this.summary,
      ocrText: ocrText ?? this.ocrText,
      images: images ?? this.images,
      reminder3DaysTime: reminder3DaysTime ?? this.reminder3DaysTime,
      reminder1DayTime: reminder1DayTime ?? this.reminder1DayTime,
      reminder12HoursTime: reminder12HoursTime ?? this.reminder12HoursTime,
      reminderCustomTime: reminderCustomTime ?? this.reminderCustomTime,
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
