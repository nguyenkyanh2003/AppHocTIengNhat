import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/payment_plan.dart';
import 'payment_faq_item.dart';

/// Đầu trang chọn gói.
class PaymentHeader extends StatelessWidget {
  const PaymentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, size: 64, color: context.colors.primary),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Chọn Gói Phù Hợp',
            style: TextStyle(fontSize: AppTypography.headline, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mở khóa tất cả tính năng học tập',
            style: TextStyle(fontSize: AppTypography.body, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Gói người dùng đang dùng. Mọi tài khoản bắt đầu ở gói miễn phí; gói trả phí
/// chỉ có sau khi quản trị viên duyệt yêu cầu.
class PaymentCurrentPlan extends StatelessWidget {
  const PaymentCurrentPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói Hiện Tại',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary),
                ),
                Text(
                  'Bạn đang sử dụng: Gói Cơ Bản (Miễn phí)',
                  style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Câu hỏi thường gặp về đăng ký gói.
class PaymentFaqSection extends StatelessWidget {
  const PaymentFaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu Hỏi Thường Gặp',
            style: TextStyle(fontSize: AppTypography.subtitle, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.md),
          PaymentFaqItem(
            question: 'Yêu cầu được xử lý như thế nào?',
            answer: 'Yêu cầu sẽ ở trạng thái chờ cho đến khi quản trị viên xác nhận.',
          ),
          PaymentFaqItem(
            question: 'Tôi có thể kiểm tra ở đâu?',
            answer: 'Bạn có thể xem trạng thái trong phần lịch sử giao dịch.',
          ),
          PaymentFaqItem(
            question: 'Ứng dụng đã thanh toán tự động chưa?',
            answer: 'Chưa. Phiên bản đồ án hiện tạo yêu cầu để quản trị viên duyệt, không tự động thu tiền.',
          ),
        ],
      ),
    );
  }
}

/// Hỏi lại trước khi gửi yêu cầu đăng ký [plan].
Future<bool> confirmPaymentPlan(BuildContext context, PaymentPlan plan) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xác Nhận Đăng Ký'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bạn chắc chắn muốn nâng cấp không?'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Gói: ${plan.name}\nChi phí: ${plan.price}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Xác Nhận'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
