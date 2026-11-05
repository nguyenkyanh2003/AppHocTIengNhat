import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../auth/providers/auth_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/profile_avatar_section.dart';
import '../../../core/state/view_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return AppScaffold(
      title: 'Thông tin cá nhân',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed:
              user == null ? null : () => showEditProfileDialog(context, user),
          tooltip: 'Chỉnh sửa thông tin',
        ),
      ],
      body: ContentWidthLimit(
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await authProvider.refreshUser();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật thông tin'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar Section
                      ProfileAvatarSection(
                          user: user,
                          selectedImageBytes: _selectedImageBytes,
                          isUploading: _isUploading,
                          pickAndUploadAvatar: _pickAndUploadAvatar),
                      const SizedBox(height: 24),

                      // Info Cards
                      _buildInfoCard(
                        title: 'Thông tin cơ bản',
                        children: [
                          _buildInfoRow(Icons.person, 'Họ tên',
                              user.fullName ?? 'Chưa cập nhật'),
                          _buildInfoRow(Icons.alternate_email, 'Tên đăng nhập',
                              user.username),
                          _buildInfoRow(Icons.email, 'Email', user.email),
                          _buildInfoRow(Icons.phone, 'Số điện thoại',
                              user.phone ?? 'Chưa cập nhật'),
                          _buildInfoRow(
                              Icons.cake,
                              'Ngày sinh',
                              user.dateOfBirth != null
                                  ? '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}'
                                  : 'Chưa cập nhật'),
                          _buildInfoRow(Icons.wc, 'Giới tính',
                              user.gender ?? 'Chưa cập nhật'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        title: 'Học tập',
                        children: [
                          _buildInfoRow(Icons.school, 'Trình độ',
                              user.currentLevel ?? 'N5'),
                          _buildInfoRow(Icons.stars, 'Điểm tích lũy',
                              '${user.points ?? 0} XP'),
                          _buildInfoRow(Icons.timer, 'Tổng thời gian học',
                              '${user.totalStudyTime ?? 0} phút'),
                          _buildInfoRow(
                              Icons.local_fire_department,
                              'Streak hiện tại',
                              '${user.currentStreak ?? 0} ngày'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        title: 'Tài khoản',
                        children: [
                          _buildInfoRow(Icons.verified_user, 'Trạng thái',
                              user.status ?? 'active'),
                          _buildInfoRow(Icons.calendar_today, 'Ngày tạo',
                              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                          _buildInfoRow(
                              Icons.login,
                              'Đăng nhập gần nhất',
                              user.lastLogin != null
                                  ? '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year}'
                                  : 'Chưa có dữ liệu'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: AppTypography.subtitle,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: context.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImageBytes = bytes;
          _isUploading = true;
        });

        // Upload to server
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.uploadAvatar(bytes, image.name);

        if (mounted) {
          setState(() => _isUploading = false);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật ảnh đại diện thành công!'),
                backgroundColor: AppColors.successStrong,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Lỗi: ${authProvider.error ?? "Không thể cập nhật ảnh"}'),
                backgroundColor: AppColors.errorStrong,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: ${userMessageOf(e)}')),
        );
        setState(() => _isUploading = false);
      }
    }
  }
}
