import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';

/// "Chào buổi sáng / chiều / tối, {tên}" trên nền màn, kèm một dòng khích lệ.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key, required this.name, required this.now});

  /// Tên hiển thị; `null` khi hồ sơ chưa có tên thì chỉ chào.
  final String? name;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);
    final greeting = switch (greetingPeriod(now)) {
      GreetingPeriod.morning => l10n.greetingMorning,
      GreetingPeriod.afternoon => l10n.greetingAfternoon,
      GreetingPeriod.evening => l10n.greetingEvening,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null || name!.trim().isEmpty
              ? greeting
              : '$greeting, ${name!.trim()}',
          style: AppTypography.ui(
              size: 24,
              weight: FontWeight.w700,
              color: calm.textPrimary,
              height: 1.25),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.homeJourney,
          style: AppTypography.ui(
              size: 15, color: calm.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

enum GreetingPeriod { morning, afternoon, evening }

/// Sáng 5:00–10:59, chiều 11:00–17:59, còn lại là tối (kể cả sau nửa đêm).
GreetingPeriod greetingPeriod(DateTime now) => switch (now.hour) {
      >= 5 && < 11 => GreetingPeriod.morning,
      >= 11 && < 18 => GreetingPeriod.afternoon,
      _ => GreetingPeriod.evening,
    };
