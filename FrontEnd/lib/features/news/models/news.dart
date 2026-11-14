import '../../../core/network/api_client.dart';

class News {
  const News({
    required this.id,
    required this.title,
    required this.description,
    required this.contentHtml,
    required this.views,
    required this.createdAt,
    this.imageUrl,
    this.source,
    this.level,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    final image = json['image_url'] as String?;
    return News(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      contentHtml: json['content_html'] as String? ?? '',
      imageUrl: image == null || image.isEmpty ? null : ApiClient.resolveAssetUrl(image),
      source: json['source'] as String?,
      level: json['level'] as String?,
      views: json['views'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String description;
  final String contentHtml;

  /// Địa chỉ đầy đủ của ảnh bìa (đường dẫn tương đối của server đã được nối host).
  final String? imageUrl;
  final String? source;
  final String? level;
  final int views;
  final DateTime createdAt;

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} tuần trước';
    return '${(difference.inDays / 30).floor()} tháng trước';
  }
}
