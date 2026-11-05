import 'package:flutter/material.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import 'create_report_screen.dart';
import 'my_reports_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Báo Cáo & Góp Ý',
      // Trước đây hai mục này nằm trên `BottomNavigationBar` — nay `AppShell`
      // đã giữ chỗ đó cho điều hướng chính, nên chúng thành tab của trang.
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.feedback), text: 'Gửi Báo Cáo'),
          Tab(icon: Icon(Icons.history), text: 'Báo Cáo Của Tôi'),
        ],
      ),
      body: ContentWidthLimit(
        child: TabBarView(
          controller: _tabController,
          children: const [
            CreateReportScreen(),
            MyReportsScreen(),
          ],
        ),
      ),
    );
  }
}
