class SRSProgress {
  final String id;
  final String userId;
  final String itemId;
  final String itemType; // 'Vocabulary' or 'Kanji'
  final int box; // 1-5 (Leitner system)
  final DateTime nextReview;
  final int streak;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SRSProgress({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.box,
    required this.nextReview,
    this.streak = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SRSProgress.fromJson(Map<String, dynamic> json) {
    return SRSProgress(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      itemId: json['item_id'] ?? '',
      itemType: json['item_type'] ?? 'Vocabulary',
      box: json['box'] ?? 1,
      nextReview: DateTime.parse(json['next_review']),
      streak: json['streak'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'item_id': itemId,
      'item_type': itemType,
      'box': box,
      'next_review': nextReview.toIso8601String(),
      'streak': streak,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Calculate next review time based on rating
  /// Rating: 1 (Again), 2 (Hard), 3 (Good), 4 (Easy)
  static DateTime calculateNextReview(int currentBox, int rating) {
    final now = DateTime.now();
    
    // Rating 1: Move back to box 1, review in 1 minute
    if (rating == 1) {
      return now.add(const Duration(minutes: 1));
    }
    
    // Rating 2: Stay in same box, review in 6 hours
    if (rating == 2) {
      return now.add(const Duration(hours: 6));
    }
    
    // Rating 3-4: Move to next box
    final newBox = (currentBox + 1).clamp(1, 5);
    
    // Leitner intervals: 1 day, 3 days, 7 days, 14 days, 30 days
    final intervals = [1, 3, 7, 14, 30];
    final daysToAdd = intervals[newBox - 1];
    
    // Rating 4 (Easy): Add extra time
    final extraDays = rating == 4 ? 2 : 0;
    
    return now.add(Duration(days: daysToAdd + extraDays));
  }

  /// Get new box level based on rating
  static int getNewBox(int currentBox, int rating) {
    if (rating == 1) return 1; // Move back to box 1
    if (rating == 2) return currentBox; // Stay in same box
    return (currentBox + 1).clamp(1, 5); // Move to next box
  }

  SRSProgress copyWith({
    String? id,
    String? userId,
    String? itemId,
    String? itemType,
    int? box,
    DateTime? nextReview,
    int? streak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SRSProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      box: box ?? this.box,
      nextReview: nextReview ?? this.nextReview,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
