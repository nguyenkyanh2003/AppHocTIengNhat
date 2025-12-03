class Notebook {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String type; // 'general', 'vocabulary', 'grammar', 'kanji'
  final String? relatedItemId;
  final String? relatedItemType;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notebook({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    this.relatedItemId,
    this.relatedItemType,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'general',
      relatedItemId: json['related_item_id'],
      relatedItemType: json['related_item_type'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'related_item_id': relatedItemId,
      'related_item_type': relatedItemType,
      'tags': tags,
    };
  }

  Notebook copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? type,
    String? relatedItemId,
    String? relatedItemType,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notebook(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      relatedItemType: relatedItemType ?? this.relatedItemType,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
