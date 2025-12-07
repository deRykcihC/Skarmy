import 'dart:io';

class Screenshot {
  final String id;
  final File file;
  final String? description;
  final List<String> tags;
  final String category;
  final bool analyzed;
  final DateTime? timestamp;

  Screenshot({
    required this.id,
    required this.file,
    this.description,
    this.tags = const [],
    this.category = 'Pending',
    this.analyzed = false,
    this.timestamp,
  });

  Screenshot copyWith({
    String? id,
    File? file,
    String? description,
    List<String>? tags,
    String? category,
    bool? analyzed,
    DateTime? timestamp,
  }) {
    return Screenshot(
      id: id ?? this.id,
      file: file ?? this.file,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      analyzed: analyzed ?? this.analyzed,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
