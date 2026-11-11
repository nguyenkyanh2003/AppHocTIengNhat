import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../achievements/models/achievement.dart';
import '../../achievements/models/achievement_labels.dart';
import '../models/admin_achievement.dart';
import '../providers/admin_provider.dart';

/// Form thêm huy hiệu ([initial] null), sửa ([initial]) hoặc nhân bản
/// ([initial] kèm [asCopy]: tạo huy hiệu mới từ nội dung có sẵn).
Future<void> showAchievementFormDialog(
  BuildContext context, {
  Achievement? initial,
  bool asCopy = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AchievementFormDialog(initial: initial, asCopy: asCopy),
  );
}

class _AchievementFormDialog extends StatefulWidget {
  const _AchievementFormDialog({required this.initial, required this.asCopy});

  final Achievement? initial;
  final bool asCopy;

  @override
  State<_AchievementFormDialog> createState() => _AchievementFormDialogState();
}

class _AchievementFormDialogState extends State<_AchievementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameVi;
  late final TextEditingController _name;
  late final TextEditingController _descriptionVi;
  late final TextEditingController _description;
  late final TextEditingController _icon;
  late final TextEditingController _requirement;
  late final TextEditingController _xp;
  late String _category;
  late String _rarity;
  late bool _isActive;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.initial != null && !widget.asCopy;

  String get _title {
    if (widget.initial == null) return 'Thêm thành tích';
    return widget.asCopy ? 'Nhân bản thành tích' : 'Sửa thành tích';
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final copySuffix = widget.asCopy ? ' (bản sao)' : '';
    _nameVi = TextEditingController(
      text: initial == null ? '' : '${initial.displayName}$copySuffix',
    );
    _name = TextEditingController(
      text: initial == null || initial.name.isEmpty
          ? ''
          : '${initial.name}${widget.asCopy ? ' (copy)' : ''}',
    );
    _descriptionVi = TextEditingController(text: initial?.displayDescription);
    _description = TextEditingController(text: initial?.description);
    _icon = TextEditingController(text: initial?.icon ?? '🏆');
    _requirement = TextEditingController(
      text: initial == null ? '' : '${initial.requirementValue}',
    );
    _xp = TextEditingController(text: '${initial?.xpReward ?? 100}');
    _category = initial?.category ?? 'vocabulary';
    _rarity = initial?.rarity ?? 'common';
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _nameVi,
      _name,
      _descriptionVi,
      _description,
      _icon,
      _requirement,
      _xp,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final provider = context.read<AdminProvider>();
    final draft = AchievementDraft(
      nameVi: _nameVi.text,
      name: _name.text,
      descriptionVi: _descriptionVi.text,
      description: _description.text,
      icon: _icon.text,
      category: _category,
      requirementValue: int.parse(_requirement.text.trim()),
      xpReward: int.parse(_xp.text.trim()),
      rarity: _rarity,
      isActive: _isActive,
    );
    final error = _isEditing
        ? await provider.updateAchievement(widget.initial!.id, draft)
        : await provider.createAchievement(draft);
    if (!mounted) return;

    // Lỗi thì giữ hộp thoại: đóng lại sẽ mất những gì admin vừa nhập.
    if (error != null) {
      setState(() {
        _isSaving = false;
        _error = error;
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Đã cập nhật!' : 'Đã thêm thành tích mới!'),
        backgroundColor: AppColors.successStrong,
      ),
    );
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập' : null;

  static String? Function(String?) _wholeNumber(int min, int max) {
    return (value) {
      final number = int.tryParse(value?.trim() ?? '');
      return number == null || number < min || number > max
          ? 'Nhập số nguyên từ $min đến $max'
          : null;
    };
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final MapEntry(:key, value: text) in options.entries)
            DropdownMenuItem(
              value: key,
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _textField(_nameVi, 'Tên hiển thị (tiếng Việt)',
                  validator: _required),
              _textField(_descriptionVi, 'Mô tả (tiếng Việt)',
                  validator: _required, maxLines: 2),
              _textField(_name, 'Tên tiếng Anh (tuỳ chọn)'),
              _textField(_description, 'Mô tả tiếng Anh (tuỳ chọn)',
                  maxLines: 2),
              _textField(_icon, 'Biểu tượng (emoji)', validator: _required),
              _dropdown(
                label: 'Tiêu chí',
                value: _category,
                options: achievementCriterionLabels,
                onChanged: (value) => setState(() => _category = value),
              ),
              _textField(_requirement, 'Số cần đạt',
                  isNumber: true, validator: _wholeNumber(1, 1000000)),
              _textField(_xp, 'XP thưởng',
                  isNumber: true, validator: _wholeNumber(0, 100000)),
              _dropdown(
                label: 'Độ hiếm',
                value: _rarity,
                options: achievementRarityLabels,
                onChanged: (value) => setState(() => _rarity = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hiển thị với người học'),
                subtitle: const Text(
                  'Tắt để ẩn mà không xoá: người đã đạt vẫn giữ huy hiệu.',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    _error!,
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }
}

/// Xác nhận rồi xoá huy hiệu, nói rõ ảnh hưởng tới người đã đạt.
void confirmDeleteAchievement(
  BuildContext context,
  AdminAchievement achievement,
) {
  final definition = achievement.definition;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text(
        'Xóa thành tích "${definition.displayName}"?\n\n'
        '${achievement.unlocked} người đã mở sẽ mất huy hiệu này, XP đã cộng vẫn giữ. '
        'Muốn giữ lại cho họ, hãy sửa và tắt "Hiển thị với người học".',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(dialogContext);
            final navigator = Navigator.of(dialogContext);
            final error = await dialogContext
                .read<AdminProvider>()
                .deleteAchievement(definition.id);
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: Text(error ?? 'Đã xóa thành tích!'),
                backgroundColor: error == null
                    ? AppColors.successStrong
                    : AppColors.errorStrong,
              ),
            );
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.errorStrong),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
