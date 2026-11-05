import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../app/theme/app_tokens.dart';
import 'admin_achievement_style.dart';

/// Hộp thoại thêm thành tích.
void showAchievementAddDialog(BuildContext context) {
  final hostContext = context;
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final iconController = TextEditingController();
  final xpController = TextEditingController();
  final conditionController = TextEditingController();
  String selectedRarity = 'common';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Thêm Achievement Mới'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên achievement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji)',
                border: OutlineInputBorder(),
                hintText: '🎯',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: xpController,
              decoration: const InputDecoration(
                labelText: 'XP thưởng',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRarity,
              decoration: const InputDecoration(
                labelText: 'Độ hiếm',
                border: OutlineInputBorder(),
              ),
              items: ['common', 'rare', 'epic', 'legendary']
                  .map((rarity) => DropdownMenuItem(
                        value: rarity,
                        child: Text(achievementRarityLabel(rarity)),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedRarity = value!;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: conditionController,
              decoration: const InputDecoration(
                labelText: 'Số lượng cần đạt',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final adminProvider = context.read<AdminProvider>();
            final success = await adminProvider.createAchievement({
              'name': nameController.text,
              'description': descController.text,
              'icon': iconController.text,
              'xp': int.tryParse(xpController.text) ?? 0,
              'rarity': selectedRarity,
              'condition': conditionController.text,
            });

            if (hostContext.mounted && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(hostContext).showSnackBar(
                SnackBar(
                  content: Text(
                      success ? 'Đã thêm achievement mới!' : 'Lỗi khi thêm!'),
                  backgroundColor:
                      success ? AppColors.successStrong : AppColors.errorStrong,
                ),
              );
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    ),
  );
}

/// Hộp thoại sửa thành tích.
void showAchievementEditDialog(
    BuildContext context, Map<String, dynamic> achievement) {
  final hostContext = context;
  final nameController = TextEditingController(text: achievement['name']);
  final descController =
      TextEditingController(text: achievement['description']);
  final iconController = TextEditingController(text: achievement['icon']);
  final xpController = TextEditingController(text: '${achievement['xp'] ?? 0}');
  final conditionController =
      TextEditingController(text: '${achievement['condition'] ?? 1}');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chỉnh Sửa Achievement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên achievement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: xpController,
              decoration: const InputDecoration(
                labelText: 'XP thưởng',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: conditionController,
              decoration: const InputDecoration(
                labelText: 'Số lượng cần đạt',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final adminProvider = context.read<AdminProvider>();
            final id = achievement['id'] ?? achievement['_id'];
            final success = await adminProvider.updateAchievement(id, {
              'name': nameController.text,
              'description': descController.text,
              'icon': iconController.text,
              'xp': int.tryParse(xpController.text) ?? 0,
              'condition': conditionController.text,
              'category': achievement['category'],
              'requirement_type': achievement['requirement_type'],
              'rarity': achievement['rarity'],
            });

            if (hostContext.mounted && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(hostContext).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã cập nhật!' : 'Lỗi khi cập nhật!'),
                  backgroundColor:
                      success ? AppColors.successStrong : AppColors.errorStrong,
                ),
              );
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
}

/// Xác nhận rồi xoá thành tích.
void confirmDeleteAchievement(
    BuildContext context, Map<String, dynamic> achievement) {
  final hostContext = context;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text(
        'Bạn có chắc muốn xóa achievement "${achievement['name']}"?\n\n'
        '${achievement['unlocked'] ?? 0} người dùng đã mở khóa achievement này.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final adminProvider = context.read<AdminProvider>();
            final id = achievement['id'] ?? achievement['_id'];
            final success = await adminProvider.deleteAchievement(id);

            if (hostContext.mounted && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(hostContext).showSnackBar(
                SnackBar(
                  content:
                      Text(success ? 'Đã xóa achievement!' : 'Lỗi khi xóa!'),
                  backgroundColor:
                      success ? AppColors.successStrong : AppColors.errorStrong,
                ),
              );
            }
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.errorStrong),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
