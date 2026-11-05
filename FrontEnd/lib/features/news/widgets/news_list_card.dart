import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/news_provider.dart';
import '../models/news.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/level_badge.dart';

/// Một bài trong danh sách tin tức.
class NewsListCard extends StatelessWidget {
  const NewsListCard({
    super.key,
    required this.news,
    required this.provider,
  });

  final News news;
  final NewsProvider provider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/news/${news.id}');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with consistent aspect ratio
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    news.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: context.colors.border,
                        child: const Icon(Icons.image, size: 48),
                      );
                    },
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    news.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer: Level, Views, Time, Bookmark
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (news.level != null)
                              LevelBadge(news.level!, compact: true),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility,
                                    size: 14,
                                    color: context.colors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${news.views}',
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
                      ),
                      IconButton(
                        icon: Icon(
                          provider.isBookmarked(news.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: provider.isBookmarked(news.id)
                              ? context.colors.error
                              : context.colors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          provider.toggleBookmark(news.id);
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
