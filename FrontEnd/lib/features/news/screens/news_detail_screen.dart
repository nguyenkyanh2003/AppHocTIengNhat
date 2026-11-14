import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/news.dart';
import '../widgets/news_article_view.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailScreen({Key? key, required this.newsId}) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadAfterFrame();
  }

  /// Cùng route chỉ đổi mã (sửa địa chỉ trên web) thì màn được dùng lại,
  /// `initState` không chạy lần nữa: phải tự tải bài mới.
  @override
  void didUpdateWidget(covariant NewsDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newsId != widget.newsId) _loadAfterFrame();
  }

  /// Sau khung hình: đang dựng cây thì provider chưa được phép báo thay đổi.
  void _loadAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context.read<NewsProvider>().loadDetail(widget.newsId);

  /// Bài đang đọc là state dùng chung, nên quay về từ một tin liên quan phải
  /// tải lại bài của màn này.
  Future<void> _openRelated(News news) async {
    await context.push('/news/${news.id}');
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    // Bài có ảnh bìa làm thanh tiêu đề; lúc đang tải hay lỗi thì cần thanh
    // tiêu đề thường để còn nút quay lại.
    return Scaffold(
      appBar: provider.detailState.hasData ? null : AppBar(title: const Text('Chi tiết tin tức')),
      body: AsyncView<News>(
        state: provider.detailState,
        onRetry: _load,
        builder: (context, news) {
          return NewsArticleView(
            news: news,
            related: provider.related,
            bookmarked: provider.isBookmarked(news.id),
            onToggleBookmark: () => provider.toggleBookmark(news.id),
            onOpenRelated: _openRelated,
          );
        },
      ),
    );
  }
}
