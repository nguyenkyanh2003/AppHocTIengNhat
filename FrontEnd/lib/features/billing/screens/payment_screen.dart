import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/payment_plan.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_plan_card.dart';
import '../widgets/payment_sections.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentProvider(),
      child: const _PaymentView(),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView();

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentProvider>();
    final signedIn = context.select<AuthProvider, bool>((auth) => auth.user != null);
    final plan = payment.selectedPlan;

    return AppScaffold(
      title: 'Nâng Cấp Gói Dịch Vụ',
      body: SingleChildScrollView(
        child: ContentPane(
          maxWidth: AppContentWidth.dashboard,
          child: Column(
            children: [
              const PaymentHeader(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    for (final option in paymentPlans)
                      PaymentPlanCard(
                        plan: option,
                        isSelected: option.id == plan.id,
                        selectPlan: payment.selectPlan,
                      ),
                  ],
                ),
              ),
              if (signedIn) const PaymentCurrentPlan(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: payment.canSubmit ? () => _confirmAndSubmit(context, plan) : null,
                    icon: const Icon(Icons.credit_card),
                    label: Text(
                      payment.isFreePlanSelected ? 'Bạn đang dùng ${plan.name}' : 'Đăng Ký ${plan.name}',
                      style: const TextStyle(fontSize: AppTypography.body),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const PaymentFaqSection(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndSubmit(BuildContext context, PaymentPlan plan) async {
    final payment = context.read<PaymentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmPaymentPlan(context, plan)) return;

    final error = await payment.submit();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Đã tạo yêu cầu đăng ký. Quản trị viên sẽ xác nhận sau khi nhận thanh toán.'
              : 'Không thể tạo yêu cầu: $error',
        ),
        backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }
}
