import 'admin_json.dart';

/// Một giao dịch ở màn quản trị; server populate người mua vào `user`.
class AdminTransaction {
  const AdminTransaction({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.packageId,
    this.createdAt,
  });

  factory AdminTransaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : const <String, dynamic>{};
    final name = '${user['HoTen'] ?? ''}'.trim();
    return AdminTransaction(
      id: json['_id'] as String,
      userName: name.isNotEmpty ? name : '${user['TenDangNhap'] ?? 'Người dùng'}',
      userEmail: user['Email'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: json['amount'] as num? ?? 0,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String? ?? 'NONE',
      packageId: json['package_id'] as String?,
      createdAt: adminDateOf(json['createdAt']),
    );
  }

  final String id;
  final String userName;
  final String userEmail;
  final String type;
  final num amount;
  final String status;
  final String paymentMethod;
  final String? packageId;
  final DateTime? createdAt;

  /// Tên gói nếu là giao dịch đăng ký gói, ngược lại là loại giao dịch.
  String get title => packageId ?? type;

  /// Còn chờ quản trị viên duyệt.
  bool get isOpen => status == 'pending' || status == 'processing';
}
