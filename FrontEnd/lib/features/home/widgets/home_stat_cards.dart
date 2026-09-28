import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';

/// Hai thẻ chỉ số: chuỗi ngày học (cam) và tổng XP (vàng), chia đều một hàng.
class HomeStatCards extends StatelessWidget {
  const HomeStatCards(
      {super.key, required this.streakDays, required this.totalXp});

  final int streakDays;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);

    // Nhãn một thẻ xuống hai dòng (máy hẹp) thì thẻ kia cao theo, hai thẻ
    // luôn bằng nhau.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_outlined,
              value: '${formatThousands(streakDays)} ${l10n.days}',
              label: l10n.streakRun,
              background: calm.streakCard,
              iconBackground: calm.streakIconBg,
              iconColor: calm.streakIcon,
              valueColor: calm.streakValue,
              labelColor: calm.streakLabel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.star_outline_rounded,
              value: '${formatThousands(totalXp)} ${l10n.xp}',
              label: l10n.experience,
              background: calm.xpCard,
              iconBackground: calm.xpIconBg,
              iconColor: calm.xpIcon,
              valueColor: calm.xpValue,
              labelColor: calm.xpLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.background,
    required this.iconBackground,
    required this.iconColor,
    required this.valueColor,
    required this.labelColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color background;
  final Color iconBackground;
  final Color iconColor;
  final Color valueColor;
  final Color labelColor;

  static const _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: _radius,
      child: InkWell(
        borderRadius: _radius,
        onTap: () => context.push('/streak'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Máy 360px chỉ còn ~70px cho chữ: số tự thu nhỏ chứ không
                    // bị cắt, nhãn được xuống hai dòng.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: AppTypography.ui(
                            size: 20,
                            weight: FontWeight.w700,
                            color: valueColor,
                            height: 1.2),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.ui(
                          size: 13,
                          weight: FontWeight.w500,
                          color: labelColor,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Số có dấu chấm ngăn hàng nghìn kiểu Việt Nam: 1073 → "1.073".
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
