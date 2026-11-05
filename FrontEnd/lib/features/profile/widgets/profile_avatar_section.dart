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
            child: GestureDetector(
              onTap: isUploading ? null : pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
