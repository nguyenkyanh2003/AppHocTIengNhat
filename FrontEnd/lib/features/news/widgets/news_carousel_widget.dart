import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';
import '../models/news.dart';
import '../providers/news_provider.dart';

/// Khối "Tin tức mới" trên Trang chủ: 5 bài mới nhất cuộn ngang, thẻ thứ hai
/// lấp ló ở mép phải để người học biết còn cuộn được.
///
/// [header] (tiêu đề mục + "Xem tất cả") do Trang chủ truyền vào để cùng kiểu
/// với các mục khác, và chỉ hiện khi có bài — chưa có bài nào thì cả khối không
/// chiếm chỗ.
///
/// Mọi thẻ cao bằng nhau vì tiêu đề luôn được dành đúng chỗ hai dòng — tính từ
/// cỡ chữ × hệ số dòng cố định và mức phóng to chữ của người dùng, nên không phụ
/// thuộc font nào vẽ chữ. Không đo chiều cao nội dung (`IntrinsicHeight`): trên
/// web phép đo chạy trước khi font chữ Nhật tải xong, tính tiêu đề một dòng và
/// cắt mất dòng phụ của thẻ có tiêu đề hai dòng. Chỉ có 5 thẻ nên dựng hết một
/// lượt thay vì danh sách lười.
class NewsCarouselWidget extends StatefulWidget {
  const NewsCarouselWidget({super.key, this.header});

  final Widget? header;

  static const double _cardWidth = 260;
  static const double _imageHeight = 120;

  @override
  State<NewsCarouselWidget> createState() => _NewsCarouselWidgetState();
}

class _NewsCarouselWidgetState extends State<NewsCarouselWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<NewsProvider>();
      if (provider.newsList.isEmpty) provider.loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, _) {
        if (provider.newsList.isEmpty) return const SizedBox.shrink();
        final newsList = provider.newsList.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.header != null) widget.header!,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < newsList.length; index++) ...[
                    if (index > 0) const SizedBox(width: 12),
                    _NewsCard(news: newsList[index]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});

  final News news;

  static const _radius = BorderRadius.all(Radius.circular(18));
  static const double _titleSize = 15;
  static const double _titleLineHeight = 1.35;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final placeholder = Container(
      height: NewsCarouselWidget._imageHeight,
      color: calm.kanjiTile,
      alignment: Alignment.center,
      child: Icon(Icons.newspaper_rounded, size: 40, color: calm.textSecondary),
    );
    // Chưa có trường chuyên mục / thời gian đọc: dòng phụ là trình độ và ngày đăng.
    final meta = [
      if (news.level != null && news.level!.isNotEmpty) news.level!,
      news.timeAgo
    ].join(' · ');

    // Chỗ cho đúng hai dòng tiêu đề, theo mức phóng to chữ của người dùng.
    final titleBox = (MediaQuery.textScalerOf(context).scale(_titleSize) *
            _titleLineHeight *
            2)
        .ceilToDouble();

    return SizedBox(
      width: NewsCarouselWidget._cardWidth,
      child: Material(
        color: calm.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: _radius, side: BorderSide(color: calm.cardBorder)),
        child: InkWell(
          onTap: () => context.push('/news/${news.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news.imageUrl != null)
                Image.network(
                  news.imageUrl!,
                  height: NewsCarouselWidget._imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                )
              else
                placeholder,
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: titleBox,
                      child: Text(
                        news.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.ui(
                          size: _titleSize,
                          weight: FontWeight.w600,
                          color: calm.textPrimary,
                          height: _titleLineHeight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.ui(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: calm.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
