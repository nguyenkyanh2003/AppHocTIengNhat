import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/files/file_saver.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_content_csv.dart';
import '../widgets/excel_import_options_dialog.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../shared/widgets/app_dialog.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen> {
  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

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
          onPressed: _showImportDialog,
          tooltip: 'Import dữ liệu',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportContent,
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
                _buildTypeSelector(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Tìm kiếm ${_typeLabel(_selectedContentType).toLowerCase()}...',
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
                _buildStats(filtered),
                if (provider.error != null)
                  MaterialBanner(
                    content: Text(provider.error!),
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    actions: [
                      TextButton(
                        onPressed: provider.clearError,
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                Expanded(
                  child: provider.isLoadingContent
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Không có ${_typeLabel(_selectedContentType).toLowerCase()}',
                              ),
                            )
                          : AdaptiveTable<Map<String, dynamic>>(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              items: filtered,
                              onRefresh: _loadContent,
                              rowKey: (item) =>
                                  ValueKey(item['_id'] ?? item['id']),
                              columns: _contentColumns(),
                              cardBuilder: (context, item) =>
                                  _buildContentCard(item),
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        icon: const Icon(Icons.add),
        label: Text('Thêm ${_typeLabel(_selectedContentType)}'),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _typeChip('Từ vựng', 'vocabulary', Icons.book, Colors.blue),
            _typeChip('Kanji', 'kanji', Icons.text_fields, Colors.purple),
            _typeChip('Ngữ pháp', 'grammar', Icons.list, Colors.orange),
            _typeChip('Bài học', 'lessons', Icons.school, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final selected = _selectedContentType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: selected ? color : Colors.grey),
        label: Text(label),
        selected: selected,
        selectedColor: color.withValues(alpha: 0.18),
        onSelected: (isSelected) {
          if (!isSelected) return;
          setState(() {
            _selectedContentType = value;
            _searchController.clear();
          });
          _loadContent();
        },
      ),
    );
  }

  Widget _buildStats(List<Map<String, dynamic>> content) {
    int countLevel(String level) =>
        content.where((item) => item['level'] == level).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(content.length.toString(), 'Tổng', Colors.blue),
          _stat(countLevel('N5').toString(), 'N5', Colors.green),
          _stat(
            (content.length - countLevel('N5')).toString(),
            'N4–N1',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildContentCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _levelColor(item['level']?.toString()),
          child: Text(
            _contentLabel(item),
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _contentTitle(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _contentSubtitle(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(action, item),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa'),
              ),
            ),
            PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.copy),
                title: Text('Nhân bản'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'edit':
        _showEditor(item: item);
        break;
      case 'duplicate':
        _showEditor(item: item, duplicate: true);
        break;
      case 'delete':
        _deleteContent(item);
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

  Future<void> _showEditor({
    Map<String, dynamic>? item,
    bool duplicate = false,
  }) async {
    final type = _selectedContentType;
    final editing = item != null && !duplicate;
    final formKey = GlobalKey<FormState>();
    final controllers = _editorControllers(type, item, duplicate);
    var level =
        _levels.contains(item?['level']) ? item!['level'] as String : 'N5';

    // Biểu mẫu này chặn bấm ra ngoài để khỏi mất dữ liệu đang nhập, nhưng Esc
    // vẫn phải đóng được — `showDialog` gộp hai thứ đó vào một cờ.
    final payload = await showAppDialog<Map<String, dynamic>>(
      context: context,
      dismissOnBarrierTap: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            editing
                ? 'Chỉnh sửa ${_typeLabel(type)}'
                : duplicate
                    ? 'Nhân bản ${_typeLabel(type)}'
                    : 'Thêm ${_typeLabel(type)}',
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: _editorFields(
                  type,
                  controllers,
                  level,
                  (value) => setDialogState(() => level = value),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(
                  dialogContext,
                  _editorPayload(type, controllers, level),
                );
              },
              child: Text(editing ? 'Lưu' : 'Tạo'),
            ),
          ],
        ),
      ),
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (payload == null || !mounted) return;

    final provider = context.read<AdminProvider>();
    final id = _itemId(item);
    final success = switch (type) {
      'vocabulary' => editing
          ? await provider.updateVocabulary(id!, payload)
          : await provider.createVocabulary(payload),
      'kanji' => editing
          ? await provider.updateKanji(id!, payload)
          : await provider.createKanji(payload),
      'grammar' => editing
          ? await provider.updateGrammar(id!, payload)
          : await provider.createGrammar(payload),
      'lessons' => editing
          ? await provider.updateLesson(id!, payload)
          : await provider.createLesson(payload),
      _ => false,
    };
    if (!mounted) return;
    _message(
      success
          ? editing
              ? 'Đã cập nhật nội dung.'
              : 'Đã tạo nội dung mới.'
          : provider.error ?? 'Không thể lưu nội dung.',
      success: success,
    );
  }

  Map<String, TextEditingController> _editorControllers(
    String type,
    Map<String, dynamic>? item,
    bool duplicate,
  ) {
    String text(String key) => item?[key]?.toString() ?? '';
    String listText(String key) {
      final value = item?[key];
      return value is List ? value.join(', ') : value?.toString() ?? '';
    }

    final firstExample = item?['examples'] is List &&
            (item!['examples'] as List).isNotEmpty &&
            (item['examples'] as List).first is Map
        ? Map<String, dynamic>.from((item['examples'] as List).first as Map)
        : const <String, dynamic>{};
    var title = text(type == 'vocabulary'
        ? 'word'
        : type == 'kanji'
            ? 'character'
            : 'title');
    if (duplicate && type == 'kanji') title = '';
    if (duplicate && (type == 'grammar' || type == 'lessons')) {
      title = '$title (bản sao)';
    }

    return {
      'title': TextEditingController(text: title),
      'reading': TextEditingController(text: text('hiragana')),
      'meaning': TextEditingController(text: text('meaning')),
      'lesson': TextEditingController(
        text: _referenceId(item?[type == 'grammar' ? 'lesson_id' : 'lesson']) ??
            _referenceId(item?['lessonId']) ??
            '',
      ),
      'context': TextEditingController(text: text('usage_context')),
      'onyomi': TextEditingController(text: listText('onyomi')),
      'kunyomi': TextEditingController(text: listText('kunyomi')),
      'hanviet': TextEditingController(text: text('hanviet')),
      'structure': TextEditingController(text: text('structure')),
      'usage': TextEditingController(text: text('usage')),
      'example': TextEditingController(
        text: firstExample['sentence']?.toString() ?? '',
      ),
      'exampleMeaning': TextEditingController(
        text: firstExample['meaning']?.toString() ?? '',
      ),
      'description': TextEditingController(text: text('description')),
      'content': TextEditingController(text: text('content_html')),
      'lessonType': TextEditingController(text: text('type')),
      'order': TextEditingController(
        text: text('order').isEmpty ? '1' : text('order'),
      ),
    };
  }

  Widget _editorFields(
    String type,
    Map<String, TextEditingController> controllers,
    String level,
    ValueChanged<String> onLevelChanged,
  ) {
    final fields = <Widget>[];
    void add(Widget child) {
      if (fields.isNotEmpty) fields.add(const SizedBox(height: 12));
      fields.add(child);
    }

    switch (type) {
      case 'vocabulary':
        add(_field(controllers['title']!, 'Từ vựng', required: true));
        add(_field(controllers['reading']!, 'Hiragana', required: true));
        add(_field(controllers['meaning']!, 'Nghĩa', required: true));
        add(_field(controllers['lesson']!, 'ID bài học', required: true));
        add(_field(controllers['context']!, 'Tình huống sử dụng'));
        break;
      case 'kanji':
        add(_field(controllers['title']!, 'Ký tự Kanji', required: true));
        add(_field(controllers['meaning']!, 'Nghĩa', required: true));
        add(_field(controllers['hanviet']!, 'Âm Hán Việt'));
        add(_field(controllers['onyomi']!, 'Âm On, cách nhau bằng dấu phẩy'));
        add(_field(controllers['kunyomi']!, 'Âm Kun, cách nhau bằng dấu phẩy'));
        add(_field(controllers['lesson']!, 'ID bài học', required: true));
        break;
      case 'grammar':
        add(_field(controllers['title']!, 'Tên ngữ pháp', required: true));
        add(_field(controllers['structure']!, 'Cấu trúc', required: true));
        add(_field(controllers['meaning']!, 'Ý nghĩa', required: true));
        add(_field(controllers['usage']!, 'Cách dùng', lines: 3));
        add(_field(controllers['lesson']!, 'ID bài học (không bắt buộc)'));
        add(_field(controllers['example']!, 'Câu ví dụ'));
        add(_field(controllers['exampleMeaning']!, 'Nghĩa câu ví dụ'));
        break;
      case 'lessons':
        add(_field(controllers['title']!, 'Tiêu đề bài học', required: true));
        add(_field(controllers['order']!, 'Thứ tự',
            required: true, number: true));
        add(_field(controllers['lessonType']!, 'Loại bài học'));
        add(_field(controllers['description']!, 'Mô tả', lines: 3));
        add(_field(controllers['content']!, 'Nội dung HTML', lines: 5));
        break;
    }
    add(
      DropdownButtonFormField<String>(
        value: level,
        decoration: const InputDecoration(
          labelText: 'Cấp độ',
          border: OutlineInputBorder(),
        ),
        items: _levels
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          if (value != null) onLevelChanged(value);
        },
      ),
    );
    return Column(mainAxisSize: MainAxisSize.min, children: fields);
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int lines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập $label.'
              : number && int.tryParse(value) == null
                  ? '$label phải là số nguyên.'
                  : null
          : null,
    );
  }

  Map<String, dynamic> _editorPayload(
    String type,
    Map<String, TextEditingController> controllers,
    String level,
  ) {
    String value(String key) => controllers[key]!.text.trim();
    List<String> readings(String key) => value(key)
        .split(RegExp(r'[,;、]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    return switch (type) {
      'vocabulary' => {
          'word': value('title'),
          'hiragana': value('reading'),
          'meaning': value('meaning'),
          'level': level,
          'lesson': value('lesson'),
          if (value('context').isNotEmpty) 'usage_context': value('context'),
        },
      'kanji' => {
          'character': value('title'),
          'meaning': value('meaning'),
          'level': level,
          'lessonId': value('lesson'),
          'onyomi': readings('onyomi'),
          'kunyomi': readings('kunyomi'),
          if (value('hanviet').isNotEmpty) 'hanviet': value('hanviet'),
        },
      'grammar' => {
          'title': value('title'),
          'structure': value('structure'),
          'meaning': value('meaning'),
          'level': level,
          if (value('usage').isNotEmpty) 'usage': value('usage'),
          if (value('lesson').isNotEmpty) 'lessonID': value('lesson'),
          if (value('example').isNotEmpty)
            'examples': [
              {
                'sentence': value('example'),
                'meaning': value('exampleMeaning'),
              },
            ],
        },
      'lessons' => {
          'title': value('title'),
          'level': level,
          'order': int.parse(value('order')),
          if (value('lessonType').isNotEmpty) 'type': value('lessonType'),
          if (value('description').isNotEmpty)
            'description': value('description'),
          if (value('content').isNotEmpty) 'content_html': value('content'),
        },
      _ => const {},
    };
  }

  Future<void> _deleteContent(Map<String, dynamic> item) async {
    final id = _itemId(item);
    if (id == null) {
      _message('Nội dung không có ID hợp lệ.', success: false);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa “${_contentTitle(item)}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<AdminProvider>();
    final success = switch (_selectedContentType) {
      'vocabulary' => await provider.deleteVocabulary(id),
      'kanji' => await provider.deleteKanji(id),
      'grammar' => await provider.deleteGrammar(id),
      'lessons' => await provider.deleteLesson(id),
      _ => false,
    };
    if (!mounted) return;
    _message(
      success ? 'Đã xóa nội dung.' : provider.error ?? 'Không thể xóa.',
      success: success,
    );
  }

  void _showImportDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Import ${_typeLabel(_selectedContentType)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_view),
              title: const Text('Import từ CSV'),
              subtitle: const Text('Dòng đầu tiên phải chứa tên các trường.'),
              onTap: () {
                Navigator.pop(dialogContext);
                _importCsv();
              },
            ),
            if (_selectedContentType == 'vocabulary' ||
                _selectedContentType == 'kanji')
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Import từ Excel'),
                subtitle: const Text('Hỗ trợ định dạng .xls và .xlsx.'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _importExcel();
                },
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cột CSV: ${AdminContentCsv.columns(_selectedContentType).where((column) => column != '_id').join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCsv() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null || !mounted) return;

    try {
      final rows = AdminContentCsv.decode(_selectedContentType, bytes);

      final provider = context.read<AdminProvider>();
      final imported = await provider.importContent(_selectedContentType, rows);
      if (!mounted) return;
      final complete = imported == rows.length;
      _message(
        complete
            ? 'Đã import $imported dòng dữ liệu.'
            : 'Đã import $imported/${rows.length} dòng. ${provider.error ?? ''}',
        success: complete,
      );
    } catch (error) {
      if (mounted) _message('Không thể đọc CSV: $error', success: false);
    }
  }

  /// Import Excel.
  ///
  /// Với từ vựng, backend bắt buộc `lesson` và `level` cho cả tệp nên phải hỏi
  /// trước khi mở file picker. Huỷ hộp thoại là dừng hẳn: không chọn tệp và
  /// không gửi request nào.
  Future<void> _importExcel() async {
    ExcelImportOptions? options;

    if (_selectedContentType == 'vocabulary') {
      final provider = context.read<AdminProvider>();
      if (provider.lessons.isEmpty) {
        await provider.loadLessons();
      }
      if (!mounted) return;

      options = await showDialog<ExcelImportOptions>(
        context: context,
        builder: (_) => ExcelImportOptionsDialog(
          lessons: context.read<AdminProvider>().lessons,
        ),
      );
      if (options == null || !mounted) return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xls', 'xlsx'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file?.bytes == null || !mounted) return;
    final provider = context.read<AdminProvider>();
    final success = await provider.importExcel(
      _selectedContentType,
      file!.bytes!,
      file.name,
      lesson: options?.lessonId,
      level: options?.level,
    );
    if (!mounted) return;
    _message(
      success
          ? 'Đã import dữ liệu Excel.'
          : provider.error ?? 'Import thất bại.',
      success: success,
    );
  }

  Future<void> _exportContent() async {
    final rows = _contentOf(context.read<AdminProvider>());
    if (rows.isEmpty) {
      _message('Không có dữ liệu để xuất.', success: false);
      return;
    }
    try {
      final now = DateTime.now();
      final stamp =
          '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
      final bytes = AdminContentCsv.encode(_selectedContentType, rows);
      final saved = await saveBytes(
        fileName: '${_selectedContentType}_$stamp.csv',
        bytes: bytes,
        mimeType: 'text/csv;charset=utf-8',
      );
      if (mounted) {
        _message(
          saved ? 'Đã xuất ${rows.length} dòng dữ liệu.' : 'Đã hủy xuất tệp.',
          success: saved,
        );
      }
    } catch (error) {
      if (mounted) _message('Không thể xuất dữ liệu: $error', success: false);
    }
  }

  String _contentLabel(Map<String, dynamic> item) {
    final value = switch (_selectedContentType) {
      'vocabulary' => item['word'],
      'kanji' => item['character'],
      'grammar' => item['title'],
      'lessons' => item['order'],
      _ => '?',
    };
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '?' : text.characters.first;
  }

  String _contentTitle(Map<String, dynamic> item) =>
      switch (_selectedContentType) {
        'vocabulary' => '${item['word'] ?? ''} (${item['hiragana'] ?? ''})',
        'kanji' => '${item['character'] ?? ''} — ${item['meaning'] ?? ''}',
        'grammar' => '${item['title'] ?? ''} — ${item['meaning'] ?? ''}',
        'lessons' => item['title']?.toString() ?? '',
        _ => '',
      };

  String _contentSubtitle(Map<String, dynamic> item) =>
      switch (_selectedContentType) {
        'vocabulary' => '${item['meaning'] ?? ''} • ${item['level'] ?? ''}',
        'kanji' =>
          'On: ${AdminContentCsv.displayValue(item['onyomi'])} • Kun: ${AdminContentCsv.displayValue(item['kunyomi'])} • ${item['level'] ?? ''}',
        'grammar' => '${item['structure'] ?? ''} • ${item['level'] ?? ''}',
        'lessons' =>
          'Bài ${item['order'] ?? ''} • ${item['level'] ?? ''} • ${item['type'] ?? 'Chưa phân loại'}',
        _ => '',
      };

  String _typeLabel(String type) => switch (type) {
        'vocabulary' => 'Từ vựng',
        'kanji' => 'Kanji',
        'grammar' => 'Ngữ pháp',
        'lessons' => 'Bài học',
        _ => type,
      };

  Color _levelColor(String? level) => switch (level) {
        'N1' => Colors.red,
        'N2' => Colors.deepOrange,
        'N3' => Colors.amber.shade700,
        'N4' => Colors.green,
        _ => Colors.blue,
      };

  String? _itemId(Map<String, dynamic>? item) =>
      item == null ? null : _referenceId(item['_id'] ?? item['id']);

  String? _referenceId(dynamic value) {
    if (value is Map) return (value['_id'] ?? value['id'])?.toString();
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  void _message(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
