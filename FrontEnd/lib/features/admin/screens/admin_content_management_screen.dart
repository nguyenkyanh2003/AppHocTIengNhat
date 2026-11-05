import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../widgets/admin_content_format.dart';
import '../widgets/admin_content_editor.dart';
import '../widgets/admin_content_actions.dart';
import '../widgets/admin_content_card.dart';
import '../widgets/admin_content_stats.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../widgets/admin_content_type_selector.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen> {
  String _selectedContentType = 'vocabulary';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContent());
  }

  Future<void> _loadContent() async {
    final provider = context.read<AdminProvider>();
    switch (_selectedContentType) {
      case 'vocabulary':
        await provider.loadVocabulary();
        break;
      case 'kanji':
        await provider.loadKanji();
        break;
      case 'grammar':
        await provider.loadGrammar();
        break;
      case 'lessons':
        await provider.loadLessons();
        break;
    }
  }

  List<Map<String, dynamic>> _contentOf(AdminProvider provider) {
    return switch (_selectedContentType) {
      'vocabulary' => provider.vocabulary,
      'kanji' => provider.kanji,
      'grammar' => provider.grammar,
      'lessons' => provider.lessons,
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản lý nội dung',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadContent,
          tooltip: 'Làm mới',
        ),
        IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: () => showAdminContentImportDialog(context,
              selectedContentType: _selectedContentType),
          tooltip: 'Import dữ liệu',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => exportAdminContent(context,
              selectedContentType: _selectedContentType, contentOf: _contentOf),
          tooltip: 'Xuất CSV',
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, provider, child) {
            final content = _contentOf(provider);
            final search = _searchController.text.trim().toLowerCase();
            final filtered = search.isEmpty
                ? content
                : content.where((item) {
                    return item.values.any(
                      (value) =>
                          value.toString().toLowerCase().contains(search),
                    );
                  }).toList();

            return Column(
              children: [
                AdminContentTypeSelector(
                    selected: _selectedContentType, onSelect: _selectType),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Tìm kiếm ${adminContentTypeLabel(_selectedContentType).toLowerCase()}...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                AdminContentStats(content: filtered),
                if (provider.error != null && content.isNotEmpty)
                  MaterialBanner(
                    content: Text(provider.error!),
                    leading:
                        Icon(Icons.error_outline, color: context.colors.error),
                    actions: [
                      TextButton(
                        onPressed: provider.clearError,
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                Expanded(
                  child: AsyncView<List<Map<String, dynamic>>>(
                    state: ViewState.fromLegacy(
                      isLoading: provider.isLoadingContent,
                      error: content.isEmpty ? provider.error : null,
                      value: filtered,
                      isEmpty: filtered.isEmpty,
                    ),
                    onRetry: _loadContent,
                    isEmpty: (items) => items.isEmpty,
                    emptyTitle:
                        'Không có ${adminContentTypeLabel(_selectedContentType).toLowerCase()}',
                    builder: (context, filtered) =>
                        AdaptiveTable<Map<String, dynamic>>(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      items: filtered,
                      onRefresh: _loadContent,
                      rowKey: (item) => ValueKey(item['_id'] ?? item['id']),
                      columns: _contentColumns(),
                      cardBuilder: (context, item) => AdminContentCard(
                          item: item,
                          selectedContentType: _selectedContentType,
                          handleAction: _handleAction,
                          contentTitle: _contentTitle),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAdminContentEditor(context,
            selectedContentType: _selectedContentType),
        icon: const Icon(Icons.add),
        label: Text('Thêm ${adminContentTypeLabel(_selectedContentType)}'),
      ),
    );
  }

  void _selectType(String value) {
    setState(() {
      _selectedContentType = value;
      _searchController.clear();
    });
    _loadContent();
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'edit':
        showAdminContentEditor(context,
            item: item, selectedContentType: _selectedContentType);
        break;
      case 'duplicate':
        showAdminContentEditor(context,
            item: item,
            duplicate: true,
            selectedContentType: _selectedContentType);
        break;
      case 'delete':
        confirmDeleteAdminContent(context, item,
            selectedContentType: _selectedContentType,
            contentTitle: _contentTitle);
        break;
    }
  }

  /// Cot bang noi dung tren vung rong; cung du lieu voi the o man hep.
  List<AdaptiveColumn<Map<String, dynamic>>> _contentColumns() {
    return [
      AdaptiveColumn(
        label: 'Nội dung',
        minWidth: 220,
        cell: (context, item) => Text(
          (item['title'] ?? item['character'] ?? item['structure'] ?? '')
              .toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdaptiveColumn(
        label: 'Nghĩa',
        minWidth: 200,
        cell: (context, item) => Text(
          (item['meaning'] ?? '').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdaptiveColumn(
        label: 'Cấp độ',
        width: 96,
        cell: (context, item) => Text((item['level'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, item) => PopupMenuButton<String>(
          onSelected: (action) => _handleAction(action, item),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa')),
            PopupMenuItem(value: 'delete', child: Text('Xoá')),
          ],
        ),
      ),
    ];
  }

  String _contentTitle(Map<String, dynamic> item) =>
      switch (_selectedContentType) {
        'vocabulary' => '${item['word'] ?? ''} (${item['hiragana'] ?? ''})',
        'kanji' => '${item['character'] ?? ''} — ${item['meaning'] ?? ''}',
        'grammar' => '${item['title'] ?? ''} — ${item['meaning'] ?? ''}',
        'lessons' => item['title']?.toString() ?? '',
        _ => '',
      };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
