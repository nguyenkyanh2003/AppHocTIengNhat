import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/transaction_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/payment_plan.dart';
import '../widgets/payment_plan_card.dart';
import '../widgets/payment_faq_item.dart';
import '../../../core/state/view_state.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPlan = 'basic';
  bool _isSubmitting = false;
  final TransactionService _transactionService = TransactionService();
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return AppScaffold(
      title: 'Nâng Cấp Gói Dịch Vụ',
      body: SingleChildScrollView(
        child: ContentPane(
          maxWidth: AppContentWidth.dashboard,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Icon(Icons.workspace_premium,
                        size: 64, color: context.colors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Chọn Gói Phù Hợp',
                      style: TextStyle(
                        fontSize: AppTypography.headline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mở khóa tất cả tính năng học tập',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Plans
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: paymentPlans.map((plan) {
                    final isSelected = _selectedPlan == plan.id;
                    return PaymentPlanCard(
                        plan: plan,
                        isSelected: isSelected,
                        selectPlan: _selectPlan);
                  }).toList(),
                ),
              ),

              // Current plan info
              if (authProvider.user != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: context.colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gói Hiện Tại',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                              ),
                            ),
                            Text(
                              'Bạn đang sử dụng: Gói Cơ Bản (Miễn phí)',
                              style: TextStyle(
                                  fontSize: AppTypography.caption,
                                  color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // CTA Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _selectedPlan == 'basic' || _isSubmitting
                        ? null
                        : _showPaymentConfirmation,
                    icon: const Icon(Icons.credit_card),
                    label: Text(
                      _selectedPlan == 'basic'
                          ? 'Bạn đang dùng Gói Cơ Bản'
                          : 'Đăng Ký ${_getPlanName(_selectedPlan)}',
                      style: const TextStyle(fontSize: AppTypography.body),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // FAQ
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu Hỏi Thường Gặp',
                      style: TextStyle(
                        fontSize: AppTypography.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    PaymentFaqItem(
                        question: 'Yêu cầu được xử lý như thế nào?',
                        answer:
                            'Yêu cầu sẽ ở trạng thái chờ cho đến khi quản trị viên xác nhận.'),
                    PaymentFaqItem(
                        question: 'Tôi có thể kiểm tra ở đâu?',
                        answer:
                            'Bạn có thể xem trạng thái trong phần lịch sử giao dịch.'),
                    PaymentFaqItem(
                        question: 'Ứng dụng đã thanh toán tự động chưa?',
                        answer:
                            'Chưa. Phiên bản đồ án hiện tạo yêu cầu để quản trị viên duyệt, không tự động thu tiền.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentConfirmation() {
    final selectedPlan =
        paymentPlans.firstWhere((plan) => plan.id == _selectedPlan);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác Nhận Đăng Ký'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn chắc chắn muốn nâng cấp không?'),
            const SizedBox(height: 16),
            Text(
              'Gói: ${selectedPlan.name}\nChi phí: ${selectedPlan.price}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _submitSubscription(selectedPlan);
            },
            child: const Text('Xác Nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSubscription(PaymentPlan plan) async {
    setState(() => _isSubmitting = true);
    try {
      await _transactionService.createSubscriptionRequest(
        packageId: plan.id,
        amount: plan.amount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã tạo yêu cầu đăng ký. Quản trị viên sẽ xác nhận sau khi nhận thanh toán.',
          ),
          backgroundColor: AppColors.successStrong,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo yêu cầu: ${userMessageOf(error)}'),
          backgroundColor: AppColors.errorStrong,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getPlanName(String planId) {
    switch (planId) {
      case 'basic':
        return 'Gói Cơ Bản';
      case 'pro':
        return 'Gói Pro';
      case 'premium':
        return 'Gói Premium';
      default:
        return '';
    }
  }

  void _selectPlan(String planId) => setState(() => _selectedPlan = planId);
}
