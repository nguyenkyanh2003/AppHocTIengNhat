import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../reports/providers/report_provider.dart';

/// Mở ứng dụng email để liên hệ.
Future<void> sendHelpEmail(BuildContext context) async {
  final hostContext = context;
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'support@apphoctiengnhat.com',
    queryParameters: {
      'subject': 'Hỗ trợ - App Học Tiếng Nhật',
      'body': 'Xin chào,\n\nTôi cần hỗ trợ về:\n\n',
    },
  );

  try {
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (hostContext.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Không thể mở ứng dụng email. Vui lòng gửi email đến: support@apphoctiengnhat.com'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  } catch (e) {
    if (hostContext.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email: support@apphoctiengnhat.com'),
        ),
      );
    }
  }
}

/// Hộp thoại báo lỗi.
Future<void> showHelpBugReportDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _HelpReportDialog(
        title: 'Báo lỗi',
        icon: Icons.bug_report,
        color: AppColors.warning,
        type: 'bug',
        reportTitle: 'Báo lỗi từ màn Trợ giúp',
        hint: 'Mô tả chi tiết lỗi bạn gặp phải...',
        thanks: 'Cảm ơn bạn đã báo lỗi! Chúng tôi sẽ xem xét và khắc phục.',
      ),
    );

/// Hộp thoại góp ý.
Future<void> showHelpFeedbackDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _HelpReportDialog(
        title: 'Góp ý & Đề xuất',
        icon: Icons.lightbulb,
        color: AppColors.success,
        type: 'suggestion',
        reportTitle: 'Góp ý từ màn Trợ giúp',
        hint: 'Chia sẻ ý kiến hoặc đề xuất của bạn...',
        thanks: 'Cảm ơn góp ý của bạn! Chúng tôi rất trân trọng.',
      ),
    );

/// Gửi nội dung thành một báo cáo thật, để admin đọc được ở màn quản trị và người
/// dùng thấy lại trong "Báo cáo của tôi".
class _HelpReportDialog extends StatefulWidget {
  const _HelpReportDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    required this.reportTitle,
    required this.hint,
    required this.thanks,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String type;
  final String reportTitle;
  final String hint;
  final String thanks;

  @override
  State<_HelpReportDialog> createState() => _HelpReportDialogState();
}

class _HelpReportDialogState extends State<_HelpReportDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    final provider = context.read<ReportProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sent = await provider.createReport(
      type: widget.type,
      title: widget.reportTitle,
      description: text,
    );
    if (!mounted) return;

    if (sent) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.thanks),
          backgroundColor: AppColors.successStrong,
        ),
      );
      return;
    }
    setState(() {
      _sending = false;
      _error = provider.error ?? 'Không gửi được. Vui lòng thử lại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.icon, color: context.colors.readable(widget.color)),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _error,
          errorMaxLines: 3,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _send,
          child: const Text('Gửi'),
        ),
      ],
    );
  }
}

/// Hộp thoại thông tin ứng dụng.
void showHelpAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.school,
              size: 48,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'App Học Tiếng Nhật',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phiên bản 1.0.0',
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ứng dụng học tiếng Nhật toàn diện với các tính năng học từ vựng, kanji, ngữ pháp, luyện thi JLPT và nhiều hơn nữa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2024 App Học Tiếng Nhật',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
