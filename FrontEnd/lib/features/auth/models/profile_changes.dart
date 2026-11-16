import '../../../core/network/api_envelope.dart';

/// Thay đổi hồ sơ người dùng tự sửa; trường `null` là giữ nguyên.
class ProfileChanges {
  const ProfileChanges({this.fullName, this.currentLevel, this.phoneNumber, this.gender, this.dateOfBirth});

  final String? fullName;

  /// Cấp JLPT dạng `N5`...`N1`.
  final String? currentLevel;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;

  /// Tên trường giữ như backend đang nhận (`hoTen`, `trinhDo`...).
  JsonObject toJson() => {
        if (fullName != null) 'hoTen': fullName,
        if (currentLevel != null) 'trinhDo': currentLevel,
        if (phoneNumber != null) 'soDienThoai': phoneNumber,
        if (gender != null) 'gioiTinh': gender,
        if (dateOfBirth != null) 'ngaySinh': dateOfBirth!.toIso8601String(),
      };
}
