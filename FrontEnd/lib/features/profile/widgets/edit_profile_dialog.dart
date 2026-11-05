import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/models/user.dart';

/// Hộp thoại sửa thông tin cá nhân.
void showEditProfileDialog(BuildContext context, User user) {
  final hostContext = context;
  final fullNameController = TextEditingController(text: user.fullName ?? '');
  final phoneController = TextEditingController(text: user.phone ?? '');
  String selectedGender = user.gender ?? 'Nam';
  String selectedLevel = user.currentLevel ?? 'N5';
  DateTime? selectedDate = user.dateOfBirth;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: context.colors.primary),
            const SizedBox(width: AppSpacing.sm),
            const Text('Chỉnh sửa thông tin'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (!dialogContext.mounted) return;
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.cake),
                  ),
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Chọn ngày sinh',
                    style: TextStyle(
                      color: selectedDate != null
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: InputDecoration(
                  labelText: 'Giới tính',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedGender = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: InputDecoration(
                  labelText: 'Trình độ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.school),
                ),
                items: ['N5', 'N4', 'N3', 'N2', 'N1']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text('JLPT $level'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedLevel = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();

              final success = await authProvider.updateProfile(
                fullName: fullNameController.text.trim().isEmpty
                    ? null
                    : fullNameController.text.trim(),
                phoneNumber: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                gender: selectedGender,
                currentLevel: int.tryParse(
                    selectedLevel.substring(1)), // Keep as int for provider
                dateOfBirth: selectedDate,
              );

              if (!hostContext.mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật thông tin thành công!'),
                    backgroundColor: AppColors.successStrong,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Lỗi: ${authProvider.error ?? "Không thể cập nhật"}'),
                    backgroundColor: AppColors.errorStrong,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
}
