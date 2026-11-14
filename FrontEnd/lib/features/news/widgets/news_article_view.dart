import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../models/news.dart';
import '../../../shared/widgets/level_badge.dart';
import 'related_news_list.dart';

/// Một bài tin: ảnh bìa làm thanh tiêu đề, thông tin bài, nội dung HTML và tin
/// liên quan cuối bài.
class NewsArticleView extends StatelessWidget {
  const NewsArticleView({
    super.key,
    required this.news,
    required this.related,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onOpenRelated,
  });

  final News news;
  final List<News> related;
  final bool bookmarked;
  final VoidCallback onToggleBookmark;
  final ValueChanged<News> onOpenRelated;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          actions: [
            IconButton(
              icon: Icon(
                bookmarked
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: bookmarked
                    ? context.colors.error
                    : Colors.white,
              ),
              onPressed: () {
                onToggleBookmark();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bookmarked
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
                    if (related.isNotEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Tin tức liên quan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RelatedNewsList(items: related, onOpen: onOpenRelated),
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
  }
}
