import 'package:flutter/material.dart';
import '../providers/news_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Danh sách tin liên quan cuối bài.
class RelatedNewsList extends StatelessWidget {
  const RelatedNewsList({
    super.key,
    required this.provider,
  });

  final NewsProvider provider;

  @override
  Widget build(BuildContext context) {
    // Ảnh 100, đệm và khoảng cách 20, cộng ba dòng chữ theo cỡ chữ của máy.
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(AppTypography.caption) * 1.6;
    return SizedBox(
      height: 120 + lineHeight * 3,
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
                color: context.colors.surfaceVariant,
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
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          news.timeAgo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: context.colors.textSecondary,
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
}
