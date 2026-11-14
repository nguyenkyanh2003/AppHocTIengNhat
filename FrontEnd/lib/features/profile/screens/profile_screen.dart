import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../auth/providers/auth_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/profile_avatar_section.dart';
import '../widgets/profile_info_card.dart';
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

                      ProfileInfoCard(title: 'Thông tin cơ bản', rows: [
                        ProfileInfoRow(Icons.person, 'Họ tên', user.fullName ?? 'Chưa cập nhật'),
                        ProfileInfoRow(Icons.alternate_email, 'Tên đăng nhập', user.username),
                        ProfileInfoRow(Icons.email, 'Email', user.email),
                        ProfileInfoRow(Icons.phone, 'Số điện thoại', user.phone ?? 'Chưa cập nhật'),
                        ProfileInfoRow(Icons.cake, 'Ngày sinh', profileDate(user.dateOfBirth)),
                        ProfileInfoRow(Icons.wc, 'Giới tính', user.gender ?? 'Chưa cập nhật'),
                      ]),
                      const SizedBox(height: AppSpacing.lg),
                      ProfileInfoCard(title: 'Học tập', rows: [
                        ProfileInfoRow(Icons.school, 'Trình độ', user.currentLevel ?? 'N5'),
                        ProfileInfoRow(Icons.stars, 'Điểm tích lũy', '${user.points ?? 0} XP'),
                        ProfileInfoRow(Icons.timer, 'Tổng thời gian học', '${user.totalStudyTime ?? 0} phút'),
                        ProfileInfoRow(Icons.local_fire_department, 'Streak hiện tại', '${user.currentStreak ?? 0} ngày'),
                      ]),
                      const SizedBox(height: AppSpacing.lg),
                      ProfileInfoCard(title: 'Tài khoản', rows: [
                        ProfileInfoRow(Icons.verified_user, 'Trạng thái', user.status ?? 'active'),
                        ProfileInfoRow(Icons.calendar_today, 'Ngày tạo', profileDate(user.createdAt)),
                        ProfileInfoRow(
                          Icons.login,
                          'Đăng nhập gần nhất',
                          profileDate(user.lastLogin, missing: 'Chưa có dữ liệu'),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
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
