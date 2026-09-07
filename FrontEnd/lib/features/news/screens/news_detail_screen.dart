import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/news_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NewsProvider>(context, listen: false);
      provider.loadNewsDetail(widget.newsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NewsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final news = provider.selectedNews;
          if (news == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Chi tiết tin tức')),
              body: const Center(child: Text('Không tìm thấy tin tức')),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      provider.isBookmarked(news.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: provider.isBookmarked(news.id)
                          ? Colors.red
                          : Colors.white,
                    ),
                    onPressed: () {
                      provider.toggleBookmark(news.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.isBookmarked(news.id)
                                ? 'Đã lưu tin tức'
                                : 'Đã bỏ lưu tin tức',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: news.imageUrl != null
                      ? Image.network(
                          news.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 64),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 64),
                        ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadata
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              news.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Info Bar
                            Row(
                              children: [
                                if (news.level != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getLevelColor(news.level),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      news.level!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                const Icon(Icons.visibility_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${news.views} lượt xem',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  news.timeAgo,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Source
                            if (news.source != null)
                              Text(
                                'Nguồn: ${news.source}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                            const SizedBox(height: 16),
                            const Divider(),
                          ],
                        ),
                      ),

                      // HTML Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Html(
                          data: news.contentHtml,
                          style: {
                            'p': Style(
                              fontSize: FontSize(16),
                              lineHeight: LineHeight.number(1.6),
                            ),
                            'h1': Style(fontSize: FontSize(20)),
                            'h2': Style(fontSize: FontSize(18)),
                            'h3': Style(fontSize: FontSize(16)),
                            'img': Style(
                              display: Display.block,
                              margin: Margins.symmetric(vertical: 10),
                            ),
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Related News
                      if (provider.relatedNews.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Tin tức liên quan',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRelatedNewsList(context, provider),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRelatedNewsList(BuildContext context, NewsProvider provider) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.relatedNews.length,
        itemBuilder: (context, index) {
          final news = provider.relatedNews[index];
          return GestureDetector(
            onTap: () {
              provider.loadNewsDetail(news.id);
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (news.imageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        news.imageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          news.timeAgo,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getLevelColor(String? level) {
    switch (level) {
      case 'N5':
        return Colors.green;
      case 'N4':
        return Colors.lightGreen;
      case 'N3':
        return Colors.amber;
      case 'N2':
        return Colors.orange;
      case 'N1':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
