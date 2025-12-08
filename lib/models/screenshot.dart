import 'dart:io';

class Screenshot {
  final String id;
  final File file;
  final String? description;
  final List<String> tags;
  final String category;
  final bool analyzed;
  final DateTime? timestamp;
  final String? note;

  Screenshot({
    required this.id,
    required this.file,
    this.description,
    this.tags = const [],
    this.category = 'Pending',
    this.analyzed = false,
    this.timestamp,
    this.note,
  });

  Screenshot copyWith({
    String? id,
    File? file,
    String? description,
    List<String>? tags,
    String? category,
    bool? analyzed,
    DateTime? timestamp,
    String? note,
  }) {
    return Screenshot(
      id: id ?? this.id,
      file: file ?? this.file,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      analyzed: analyzed ?? this.analyzed,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }
}
