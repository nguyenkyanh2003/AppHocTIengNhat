import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/models/user.dart';

/// Ảnh đại diện và nút đổi ảnh.
class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
    required this.user,
    required this.selectedImageBytes,
    required this.isUploading,
    required this.pickAndUploadAvatar,
  });

  final User user;
  final Uint8List? selectedImageBytes;
  final bool isUploading;
  final Future<void> Function() pickAndUploadAvatar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundImage: selectedImageBytes != null
                  ? MemoryImage(selectedImageBytes!)
                  : (user.avatar != null ? NetworkImage(user.avatar!) : null)
                      as ImageProvider?,
              backgroundColor: context.colors.primarySoft,
              child: (selectedImageBytes == null && user.avatar == null)
                  ? Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: AppTypography.display,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            // Viền nền tách nút khỏi ảnh; IconButton lo nhãn, tooltip và focus.
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton.filled(
                tooltip: 'Đổi ảnh đại diện',
                onPressed: isUploading ? null : pickAndUploadAvatar,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
                icon: isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
