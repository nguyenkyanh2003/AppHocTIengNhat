import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/transaction_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPlan = 'basic';
  bool _isSubmitting = false;
  final TransactionService _transactionService = TransactionService();
  final List<PaymentPlan> _plans = [
    PaymentPlan(
      id: 'basic',
      name: 'Gói Cơ Bản',
      price: 'Miễn phí',
      amount: 0,
      icon: '🎓',
      features: [
        'Học 5 bài miễn phí',
        'Từ vựng cơ bản',
        'Các bài tập giới hạn',
        'Xem tin tức',
      ],
    ),
    PaymentPlan(
      id: 'pro',
      name: 'Gói Pro',
      price: '79,000đ/tháng',
      amount: 79000,
      icon: '⭐',
      features: [
        'Truy cập không giới hạn',
        'Tất cả bài học & kanji',
        'Bài tập nâng cao',
        'Luyện thi JLPT đầy đủ',
        'Xóa quảng cáo',
        'Hỗ trợ ưu tiên',
      ],
      recommended: true,
    ),
    PaymentPlan(
      id: 'premium',
      name: 'Gói Premium',
      price: '199,000đ/năm',
      amount: 199000,
      icon: '💎',
      features: [
        'Tất cả tính năng Pro',
        'Giảm giá 50% so với tháng',
        'Lịch sử chi tiết',
        'Export dữ liệu',
        'Hỗ trợ 24/7',
      ],
    ),
  ];

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
                child: const Column(
                  children: [
                    Icon(Icons.workspace_premium, size: 64, color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Chọn Gói Phù Hợp',
                      style: TextStyle(
                        fontSize: AppTypography.headline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mở khóa tất cả tính năng học tập',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Plans
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _plans.map((plan) {
                    final isSelected = _selectedPlan == plan.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlan = plan.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isSelected ? 8 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.1),
                                      Colors.transparent
                                    ],
                                  )
                                : null,
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plan.icon,
                                    style: const TextStyle(fontSize: AppTypography.display),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: const TextStyle(
                                            fontSize: AppTypography.title,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          plan.price,
                                          style: const TextStyle(
                                            fontSize: AppTypography.subtitle,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (plan.recommended)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Được Khuyến Nghị',
                                        style: TextStyle(
                                          fontSize: AppTypography.caption,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...plan.features.map((feature) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 20,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: const TextStyle(fontSize: AppTypography.bodySmall),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    );
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
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gói Hiện Tại',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Bạn đang sử dụng: Gói Cơ Bản (Miễn phí)',
                              style: TextStyle(
                                  fontSize: AppTypography.caption, color: AppColors.textSecondary),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Câu Hỏi Thường Gặp',
                      style: TextStyle(
                        fontSize: AppTypography.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFaqItem(
                      'Yêu cầu được xử lý như thế nào?',
                      'Yêu cầu sẽ ở trạng thái chờ cho đến khi quản trị viên xác nhận.',
                    ),
                    _buildFaqItem(
                      'Tôi có thể kiểm tra ở đâu?',
                      'Bạn có thể xem trạng thái trong phần lịch sử giao dịch.',
                    ),
                    _buildFaqItem(
                      'Ứng dụng đã thanh toán tự động chưa?',
                      'Chưa. Phiên bản đồ án hiện tạo yêu cầu để quản trị viên duyệt, không tự động thu tiền.',
                    ),
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

  Widget _buildFaqItem(String question, String answer) {
    return Column(
      children: [
        ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(answer),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  void _showPaymentConfirmation() {
    final selectedPlan = _plans.firstWhere((plan) => plan.id == _selectedPlan);
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
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo yêu cầu: $error'),
          backgroundColor: AppColors.error,
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
}

class PaymentPlan {
  final String id;
  final String name;
  final String price;
  final int amount;
  final String icon;
  final List<String> features;
  final bool recommended;

  PaymentPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.amount,
    required this.icon,
    required this.features,
    this.recommended = false,
  });
}
