import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/study_group_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/study_group.dart';

/// Hộp thoại sửa thông tin nhóm.
void showGroupEditDialog(BuildContext context, StudyGroup group) {
  final hostContext = context;
  final nameController = TextEditingController(text: group.name);
  final descController = TextEditingController(text: group.description ?? '');
  String selectedLevel = group.level;
  int maxMembers = group.maxMembers;
  bool isPrivate = group.isPrivate;
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  final ImagePicker picker = ImagePicker();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: context.colors.readable(Colors.blue[700]!)),
            const SizedBox(width: 8),
            const Text('Chỉnh sửa thông tin nhóm'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar picker
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                      maxHeight: 512,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        selectedImageBytes = bytes;
                        selectedImageName = image.name;
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: selectedImageBytes != null
                            ? MemoryImage(selectedImageBytes!)
                            : (group.avatar != null
                                ? NetworkImage(group.avatar!)
                                : null) as ImageProvider?,
                        backgroundColor: context.colors.surfaceVariant,
                        child:
                            selectedImageBytes == null && group.avatar == null
                                ? Icon(Icons.group,
                                    size: 40,
                                    color: context.colors.textSecondary)
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Nhấn để thay đổi ảnh nhóm',
                  style: TextStyle(
                      fontSize: 12, color: context.colors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên nhóm *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.group),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: InputDecoration(
                  labelText: 'Cấp độ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.school),
                ),
                items: ['ALL', 'N5', 'N4', 'N3', 'N2', 'N1']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(
                              level == 'ALL' ? 'Tất cả cấp độ' : 'JLPT $level'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedLevel = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: maxMembers.toString(),
                decoration: InputDecoration(
                  labelText: 'Số thành viên tối đa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final num = int.tryParse(value);
                  if (num != null && num >= 2 && num <= 500) {
                    maxMembers = num;
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Nhóm riêng tư'),
                subtitle:
                    const Text('Chỉ thành viên được mời mới có thể tham gia'),
                value: isPrivate,
                onChanged: (value) {
                  setState(() => isPrivate = value);
                },
                secondary: const Icon(Icons.lock),
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên nhóm')),
                );
                return;
              }

              final provider = hostContext.read<StudyGroupProvider>();

              // Upload avatar if selected
              if (selectedImageBytes != null) {
                final avatarSuccess = await provider.uploadGroupAvatar(
                  group.id,
                  selectedImageBytes!,
                  selectedImageName!,
                );

                if (!hostContext.mounted || !context.mounted) return;
                if (!avatarSuccess) {
                  ScaffoldMessenger.of(hostContext).showSnackBar(
                    SnackBar(
                        content:
                            Text(provider.error ?? 'Lỗi khi upload avatar')),
                  );
                  return;
                }
              }

              final success = await provider.updateGroup(
                groupId: group.id,
                name: nameController.text.trim(),
                description: descController.text.trim(),
                level: selectedLevel,
                isPrivate: isPrivate,
                maxMembers: maxMembers,
              );

              if (!hostContext.mounted || !context.mounted) return;
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(hostContext).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật thông tin nhóm')),
                );
                provider.loadGroupDetail(group.id);
              } else {
                ScaffoldMessenger.of(hostContext).showSnackBar(
                  SnackBar(
                      content: Text(provider.error ?? 'Lỗi khi cập nhật nhóm')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    ),
  );
}
