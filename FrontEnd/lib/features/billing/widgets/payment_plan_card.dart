import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/payment_plan.dart';

/// Một gói dịch vụ để chọn.
class PaymentPlanCard extends StatelessWidget {
  const PaymentPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.selectPlan,
  });

  final PaymentPlan plan;
  final bool isSelected;
  final void Function(String planId) selectPlan;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => selectPlan(plan.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? context.colors.primary : Colors.transparent,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: TextStyle(
                            fontSize: AppTypography.subtitle,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primary,
                          ),
                        ),
                        if (plan.recommended) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Được Khuyến Nghị',
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                color:
                                    context.colors.readable(AppColors.warning),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: context.colors.readable(AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                              fontSize: AppTypography.bodySmall),
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
  }
}
