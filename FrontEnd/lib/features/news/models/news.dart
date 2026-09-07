import '../../../core/network/api_client.dart';

class News {
  final String id;
  final String title;
  final String description;
  final String contentHtml;
  final String? imageUrl;
  final String? source;
  final String? level;
  final String? audioUrl;
  final int views;
  final DateTime createdAt;
  final DateTime? updatedAt;

  News({
    required this.id,
    required this.title,
    required this.description,
    required this.contentHtml,
    this.imageUrl,
    this.source,
    this.level,
    this.audioUrl,
    required this.views,
    required this.createdAt,
    this.updatedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    String? normalizeImageUrl(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      if (raw.startsWith('http')) return raw;
      final host = ApiClient.baseUrl.replaceFirst('/api', '');
      return raw.startsWith('/') ? '$host$raw' : '$host/$raw';
    }

    return News(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      contentHtml: json['content_html'] ?? json['content'] ?? '',
      imageUrl: normalizeImageUrl(json['image_url'] as String?),
      source: json['source'],
      level: json['level'],
      audioUrl: json['audio_url'],
      views: json['views'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'content_html': contentHtml,
      'image_url': imageUrl,
      'source': source,
      'level': level,
      'audio_url': audioUrl,
      'views': views,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else {
      return '${(difference.inDays / 30).floor()} tháng trước';
    }
  }

  String get levelColor {
    switch (level?.toUpperCase()) {
      case 'N5':
        return '#4CAF50';
      case 'N4':
        return '#8BC34A';
      case 'N3':
        return '#FFC107';
      case 'N2':
        return '#FF9800';
      case 'N1':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
}
