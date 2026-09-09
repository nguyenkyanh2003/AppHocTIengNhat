import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'Làm thế nào để bắt đầu học tiếng Nhật?',
      answer:
          'Bạn có thể bắt đầu từ mục "Bài học" trên trang chủ. Chúng tôi khuyên bạn nên học từ N5 (cơ bản) trước, sau đó tiến lên các cấp độ cao hơn. Mỗi ngày dành 15-30 phút học sẽ giúp bạn tiến bộ nhanh chóng.',
    ),
    FAQItem(
      question: 'Streak (chuỗi học) hoạt động như thế nào?',
      answer:
          'Streak là số ngày liên tiếp bạn học tập. Mỗi khi bạn hoàn thành ít nhất 1 hoạt động học tập trong ngày (học bài, làm bài tập, ôn tập flashcard...), streak sẽ được duy trì. Nếu bỏ lỡ 1 ngày, streak sẽ reset về 0.',
    ),
    FAQItem(
      question: 'XP là gì và tích lũy XP như thế nào?',
      answer:
          'XP (Experience Points) là điểm kinh nghiệm bạn nhận được khi học tập. Bạn nhận XP khi:\n• Hoàn thành bài học: 10-50 XP\n• Làm bài tập đúng: 5-20 XP/câu\n• Duy trì streak: 10 XP/ngày\n• Đạt thành tích: 50-500 XP\n\nXP giúp bạn lên level và mở khóa các thành tích mới.',
    ),
    FAQItem(
      question: 'Làm sao để ôn tập từ vựng hiệu quả?',
      answer:
          'Sử dụng tính năng Flashcard với hệ thống SRS (Spaced Repetition System). Hệ thống sẽ tự động nhắc bạn ôn tập những từ sắp quên. Ngoài ra, bạn có thể thêm từ vào Sổ tay cá nhân để ôn tập bất cứ lúc nào.',
    ),
    FAQItem(
      question: 'Tôi có thể học offline không?',
      answer:
          'Có! Vào Cài đặt > Chế độ Offline để tải xuống các bài học. Nội dung đã tải sẽ có sẵn khi không có mạng. Lưu ý: Một số tính năng như streak và bảng xếp hạng yêu cầu kết nối internet.',
    ),
    FAQItem(
      question: 'Làm thế nào để chuẩn bị cho kỳ thi JLPT?',
      answer:
          'Vào mục JLPT trên trang chủ để:\n• Làm đề thi thử các năm\n• Ôn tập theo từng phần (Từ vựng, Ngữ pháp, Đọc hiểu, Nghe)\n• Xem thống kê điểm yếu cần cải thiện\n\nChúng tôi khuyên bạn nên bắt đầu luyện thi ít nhất 3-6 tháng trước kỳ thi.',
    ),
    FAQItem(
      question: 'Làm sao để tham gia nhóm học tập?',
      answer:
          'Vào mục "Nhóm học" để tạo hoặc tham gia nhóm. Bạn có thể:\n• Tạo nhóm riêng và mời bạn bè\n• Tìm và tham gia nhóm công khai\n• Chat, chia sẻ tài liệu với thành viên\n• Thi đua với nhau trên bảng xếp hạng nhóm',
    ),
    FAQItem(
      question: 'Tôi gặp lỗi khi sử dụng ứng dụng, phải làm sao?',
      answer:
          'Thử các bước sau:\n1. Đóng và mở lại ứng dụng\n2. Kiểm tra kết nối mạng\n3. Cập nhật ứng dụng lên phiên bản mới nhất\n4. Xóa cache ứng dụng trong Cài đặt thiết bị\n\nNếu vẫn gặp lỗi, hãy liên hệ với chúng tôi qua mục "Liên hệ hỗ trợ" bên dưới.',
    ),
  ];

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
                  color: Colors.blue,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tìm câu trả lời nhanh hoặc liên hệ với chúng tôi',
                      style: TextStyle(
                        fontSize: 14,
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
                      child: _buildQuickActionCard(
                        icon: Icons.email_outlined,
                        title: 'Gửi Email',
                        subtitle: 'Liên hệ trực tiếp',
                        color: Colors.blue,
                        onTap: () => _sendEmail(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.bug_report_outlined,
                        title: 'Báo lỗi',
                        subtitle: 'Gửi báo cáo lỗi',
                        color: Colors.orange,
                        onTap: () => _reportBug(),
                      ),
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
                      child: _buildQuickActionCard(
                        icon: Icons.lightbulb_outline,
                        title: 'Góp ý',
                        subtitle: 'Đề xuất tính năng',
                        color: Colors.green,
                        onTap: () => _sendFeedback(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.info_outline,
                        title: 'Về ứng dụng',
                        subtitle: 'Thông tin & phiên bản',
                        color: Colors.purple,
                        onTap: () => _showAboutDialog(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // FAQ Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.quiz_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Câu hỏi thường gặp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                itemCount: _faqItems.length,
                itemBuilder: (context, index) {
                  return _buildFAQTile(_faqItems[index]);
                },
              ),

              const SizedBox(height: 32),

              // Contact Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vẫn cần trợ giúp?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Đội ngũ hỗ trợ sẵn sàng giúp đỡ bạn 24/7',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _sendEmail(),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Liên hệ hỗ trợ'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'App Học Tiếng Nhật',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phiên bản 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTile(FAQItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Colors.blue,
              size: 20,
            ),
          ),
          title: Text(
            item.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              item.answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail() async {
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
        if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email: support@apphoctiengnhat.com'),
          ),
        );
      }
    }
  }

  Future<void> _reportBug() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange),
            SizedBox(width: 8),
            Text('Báo lỗi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết lỗi bạn gặp phải...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Cảm ơn bạn đã báo lỗi! Chúng tôi sẽ xem xét và khắc phục sớm.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.green),
            SizedBox(width: 8),
            Text('Góp ý & Đề xuất'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Chia sẻ ý tưởng hoặc đề xuất tính năng mới...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Cảm ơn góp ý của bạn! Chúng tôi rất trân trọng.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
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
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'App Học Tiếng Nhật',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phiên bản 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ứng dụng học tiếng Nhật toàn diện với các tính năng học từ vựng, kanji, ngữ pháp, luyện thi JLPT và nhiều hơn nữa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2024 App Học Tiếng Nhật',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
