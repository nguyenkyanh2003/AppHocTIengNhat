import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/lesson_level.dart';
import '../providers/lesson_provider.dart';
import '../widgets/lesson_card.dart';
import '../widgets/lesson_level_bar.dart';
import '../widgets/lesson_situation_bar.dart';

/// Danh sách bài học, lọc theo trình độ JLPT rồi theo chủ đề.
class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final lessons = context.read<LessonProvider>();
    _searchController.text = lessons.searchQuery ?? '';

    // Nạp dữ liệu sẽ notifyListeners, nên phải đợi frame đầu dựng xong.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      lessons.openLessonList(
        defaultLevel: defaultLessonLevel(user?.currentLevel),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LessonProvider>();
    final userLevel =
        normalizeJlptLevel(context.watch<AuthProvider>().user?.currentLevel);
    final reloading = provider.isListLoading && provider.lessons.isNotEmpty;

    return AppScaffold(
      title: 'Bài học',
      body: ContentWidthLimit(
        child: Column(
          children: [
            _buildSearchField(provider),
            // Trình độ đứng trên chủ đề vì dải chủ đề đổi theo trình độ.
            LessonLevelBar(
              selectedLevel: provider.selectedLevel,
              userLevel: userLevel,
              onChanged: provider.filterByLevel,
            ),
            LessonSituationBar(
              situations: provider.situations,
              selectedSituation: provider.selectedSituation,
              onChanged: provider.filterBySituation,
            ),
            // Giữ sẵn chỗ của thanh tải để danh sách không giật khi nó hiện ra.
            SizedBox(
              height: AppSpacing.xs,
              child: reloading ? const LinearProgressIndicator() : null,
            ),
            Expanded(child: _buildList(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(LessonProvider provider) {
    return Padding(
      padding: AppSpacing.page,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài học...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    provider.searchLessons('');
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: provider.searchLessons,
      ),
    );
  }

  /// Chỉ thay danh sách bằng vòng xoay khi chưa có gì để hiện. Đang có bài thì
  /// giữ nguyên trên màn, thanh tải mảnh phía trên đã báo là đang nạp.
  Widget _buildList(LessonProvider provider) {
    if (provider.listError != null) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        color: AppColors.error,
        message: provider.listError!,
        action: ElevatedButton(
          onPressed: () => provider.loadLessons(refresh: true),
          child: const Text('Thử lại'),
        ),
      );
    }

    if (provider.lessons.isEmpty) {
      if (provider.isListLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _CenteredMessage(
        icon: Icons.book_outlined,
        color: AppColors.textDisabled,
        message: _emptyMessage(provider),
        action: provider.selectedLevel == null
            ? null
            : TextButton(
                onPressed: () => provider.filterByLevel(null),
                child: const Text('Xem mọi trình độ'),
              ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadLessons(refresh: true),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.page,
              itemCount: provider.lessons.length,
              itemBuilder: (context, index) =>
                  LessonCard(lesson: provider.lessons[index]),
            ),
          ),
          _buildPagination(provider),
        ],
      ),
    );
  }

  String _emptyMessage(LessonProvider provider) {
    if (provider.selectedSituation != null) {
      return 'Chưa có bài học cho chủ đề này ở trình độ đang chọn';
    }
    if (provider.selectedLevel != null) {
      return 'Chưa có bài học ở trình độ ${provider.selectedLevel}';
    }
    return 'Chưa có bài học nào';
  }

  Widget _buildPagination(LessonProvider provider) {
    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: provider.currentPage > 1 ? provider.previousPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          AppGap.sm,
          Text(
            'Trang ${provider.currentPage} / ${provider.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          AppGap.sm,
          IconButton(
            onPressed: provider.currentPage < provider.totalPages
                ? provider.nextPage
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// Biểu tượng, lời nhắn và một nút tuỳ chọn ở giữa vùng danh sách.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.color,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: color),
            AppGap.lg,
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (action != null) ...[AppGap.md, action!],
          ],
        ),
      ),
    );
  }
}
