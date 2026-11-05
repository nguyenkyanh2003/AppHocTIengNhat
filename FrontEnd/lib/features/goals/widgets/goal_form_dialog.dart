import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/learning_goal.dart';
import 'goal_card.dart';

/// Giới hạn khớp với schema backend (`goal.schema.js`).
const _targetMax = 100000;
const _titleMax = 120;

/// Giá trị form gửi đi. [target] `null` khi sửa mục tiêu đã hoàn thành hoặc
/// không đổi số cần đạt.
typedef GoalFormValue = ({GoalType type, int? target, String title, DateTime? deadline});

/// Form tạo hoặc sửa ([goal] khác null) một mục tiêu. Trả `null` từ [onSubmit]
/// là đã lưu (form tự đóng); ngược lại là thông điệp lỗi hiện ngay trong form.
class GoalFormDialog extends StatefulWidget {
  const GoalFormDialog({
    super.key,
    required this.counts,
    required this.onSubmit,
    this.available = const GoalAvailability(),
    this.goal,
  });

  final GoalCounts counts;

  /// Trần nội dung hiện có (số bài, số chữ Kanji trong bài): đặt cao hơn thì
  /// không bao giờ đạt được.
  final GoalAvailability available;
  final LearningGoal? goal;
  final Future<String?> Function(GoalFormValue value) onSubmit;

  @override
  State<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _target;
  late final TextEditingController _title;
  late GoalType _type;
  DateTime? _deadline;
  bool _saving = false;
  bool _submitted = false;
  String? _error;

  bool get _editing => widget.goal != null;
  bool get _targetLocked => widget.goal?.isCompleted ?? false;
  int get _current => widget.counts.of(_type);
  int? get _limit => widget.available.limitOf(_type);

  String get _helper {
    final limit = _limit;
    final have = 'Bạn đang có $_current ${_type.unit}';
    if (limit == null) return have;
    return _type == GoalType.kanji ? '$have · các bài học có $limit chữ' : '$have · hiện có $limit bài';
  }

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _type = goal?.type ?? GoalType.vocabulary;
    _target = TextEditingController(text: goal == null ? '' : '${goal.target}');
    _title = TextEditingController(text: goal?.title ?? '');
    _deadline = goal?.deadline;
  }

  @override
  void dispose() {
    _target.dispose();
    _title.dispose();
    super.dispose();
  }

  String? _validateTarget(String? text) {
    if (_targetLocked) return null;
    if (text == null || text.isEmpty) return 'Vui lòng nhập số cần đạt.';
    final value = int.tryParse(text);
    if (value == null || value < 1) return 'Số cần đạt phải là số nguyên dương.';
    if (value > _targetMax) return 'Tối đa $_targetMax.';
    if (value <= _current) return 'Hãy đặt số lớn hơn $_current.';
    // Chỉ chặn khi đổi số: mục tiêu cũ đặt trước khi có trần vẫn sửa tên, hạn được.
    final limit = _limit;
    if (limit != null && value > limit && value != widget.goal?.target) {
      return _type == GoalType.kanji
          ? 'Các bài học hiện chỉ có $limit chữ Kanji.'
          : 'Hiện chỉ có $limit bài học.';
    }
    return null;
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _deadline;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today.add(const Duration(days: 30)),
      firstDate: current != null && current.isBefore(today) ? current : today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  /// Đổi loại thì số đang có đổi theo; đã bấm gửi thì kiểm lại ngay để lỗi cũ
  /// ("lớn hơn 120" của từ vựng) không còn treo khi đã chuyển sang Kanji.
  void _changeType(GoalType? type) {
    setState(() => _type = type ?? _type);
    if (_submitted) _formKey.currentState!.validate();
  }

  Future<void> _submit() async {
    _submitted = true;
    if (!_formKey.currentState!.validate()) return;
    final target = int.tryParse(_target.text);
    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit((
      type: _type,
      // Chỉ gửi số cần đạt khi thật sự đổi được và đã đổi.
      target: _targetLocked || target == widget.goal?.target ? null : target,
      title: _title.text.trim(),
      deadline: _deadline,
    ));
    if (!mounted) return;
    if (error == null) return Navigator.pop(context);
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deadline = _deadline;

    return AlertDialog(
      title: Text(_editing ? 'Sửa mục tiêu' : 'Thêm mục tiêu'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_editing)
                  Text('Loại: ${_type.label}', style: Theme.of(context).textTheme.titleSmall)
                else
                  DropdownButtonFormField<GoalType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Loại mục tiêu'),
                    items: [
                      for (final type in GoalType.values) DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: _saving ? null : _changeType,
                  ),
                AppGap.md,
                TextFormField(
                  controller: _target,
                  enabled: !_targetLocked && !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Số cần đạt',
                    helperText: _targetLocked ? 'Đã hoàn thành — không đổi số cần đạt.' : _helper,
                    // Màn hẹp: gợi ý và lỗi xuống dòng thay vì bị cắt "…".
                    helperMaxLines: 2,
                    errorMaxLines: 2,
                  ),
                  validator: _validateTarget,
                ),
                AppGap.md,
                TextFormField(
                  controller: _title,
                  maxLength: _titleMax,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Tên mục tiêu',
                    hintText: _editing ? null : 'Để trống: "Đạt N ${_type.unit}"',
                  ),
                  validator: (value) =>
                      _editing && (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên mục tiêu.' : null,
                ),
                Row(
                  children: [
                    Expanded(child: Text(deadline == null ? 'Không đặt hạn' : 'Hạn: ${formatDate(deadline)}')),
                    TextButton(onPressed: _saving ? null : _pickDeadline, child: const Text('Chọn hạn')),
                    if (deadline != null)
                      IconButton(
                        tooltip: 'Bỏ hạn',
                        icon: const Icon(Icons.close),
                        onPressed: _saving ? null : () => setState(() => _deadline = null),
                      ),
                  ],
                ),
                if (_error != null) ...[
                  AppGap.sm,
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Huỷ')),
        FilledButton(onPressed: _saving ? null : _submit, child: Text(_editing ? 'Lưu' : 'Thêm')),
      ],
    );
  }
}
