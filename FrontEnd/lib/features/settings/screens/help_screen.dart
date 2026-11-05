import 'package:flutter/material.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/help_faq.dart';
import '../widgets/help_dialogs.dart';
import '../widgets/help_contact_card.dart';
import '../widgets/help_tiles.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Trợ giúp',
      body: SingleChildScrollView(
        child: ContentPane(
          maxWidth: AppContentWidth.dashboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chúng tôi có thể giúp gì cho bạn?',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tìm câu trả lời nhanh hoặc liên hệ với chúng tôi',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: HelpQuickActionCard(
                          icon: Icons.email_outlined,
                          title: 'Gửi Email',
                          subtitle: 'Liên hệ trực tiếp',
                          color: AppColors.primary,
                          onTap: () => sendHelpEmail(context)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HelpQuickActionCard(
                          icon: Icons.bug_report_outlined,
                          title: 'Báo lỗi',
                          subtitle: 'Gửi báo cáo lỗi',
                          color: AppColors.warning,
                          onTap: () => showHelpBugReportDialog(context)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: HelpQuickActionCard(
                          icon: Icons.lightbulb_outline,
                          title: 'Góp ý',
                          subtitle: 'Đề xuất tính năng',
                          color: AppColors.success,
                          onTap: () => showHelpFeedbackDialog(context)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HelpQuickActionCard(
                          icon: Icons.info_outline,
                          title: 'Về ứng dụng',
                          subtitle: 'Thông tin & phiên bản',
                          color: Colors.purple,
                          onTap: () => showHelpAboutDialog(context)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // FAQ Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.quiz_outlined, color: context.colors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Câu hỏi thường gặp',
                        style: TextStyle(
                          fontSize: AppTypography.subtitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // FAQ List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: helpFaqItems.length,
                itemBuilder: (context, index) {
                  return HelpFaqTile(item: helpFaqItems[index]);
                },
              ),

              const SizedBox(height: 32),

              // Contact Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: HelpContactCard(),
              ),

              const SizedBox(height: 32),

              // App Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'App Học Tiếng Nhật',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phiên bản 1.0.0',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: context.colors.textDisabled,
                      ),
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
}
