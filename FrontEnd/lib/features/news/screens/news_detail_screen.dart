import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/news_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/related_news_list.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/news.dart';
import '../../../shared/widgets/level_badge.dart';

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
          final news = provider.selectedNews;
          if (provider.isLoadingDetail ||
              provider.error != null ||
              news == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Chi tiết tin tức')),
              body: AsyncView<News>(
                state: ViewState.detail(
                  isLoading: provider.isLoadingDetail,
                  error: provider.error,
                  value: news,
                ),
                onRetry: () => provider.loadNewsDetail(widget.newsId),
                builder: (context, _) => const SizedBox.shrink(),
              ),
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
                          ? context.colors.error
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
                              color: context.colors.border,
                              child: const Icon(Icons.image, size: 64),
                            );
                          },
                        )
                      : Container(
                          color: context.colors.border,
                          child: const Icon(Icons.image, size: 64),
                        ),
                ),
              ),

              // Content
              // Ảnh bìa trải hết bề rộng; phần bài đọc bó lại theo bề rộng
              // đọc được, nếu không thì trên desktop mỗi dòng dài cả nghìn px.
              SliverLayoutBuilder(
                builder: (context, constraints) => SliverPadding(
                  padding: ContentPane.paddingFor(
                    constraints.crossAxisExtent,
                    maxWidth: AppContentWidth.reading,
                    base: EdgeInsets.zero,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      color: context.colors.surface,
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
                                    fontSize: AppTypography.title,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Info Bar
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (news.level != null)
                                      LevelBadge(news.level!),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.visibility_outlined,
                                            size: 16,
                                            color:
                                                context.colors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${news.views} lượt xem',
                                          style: TextStyle(
                                            fontSize: AppTypography.caption,
                                            color: context.colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      news.timeAgo,
                                      style: TextStyle(
                                        fontSize: AppTypography.caption,
                                        color: context.colors.textSecondary,
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
                                      fontSize: AppTypography.caption,
                                      color: context.colors.textSecondary,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Tin tức liên quan',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RelatedNewsList(provider: provider),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
