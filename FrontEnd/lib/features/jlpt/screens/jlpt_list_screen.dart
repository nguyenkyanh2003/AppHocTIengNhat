import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jlpt_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../models/jlpt_models.dart';
import './jlpt_exam_screen.dart';
import './jlpt_practice_screen.dart';

class JLPTListScreen extends StatefulWidget {
  const JLPTListScreen({super.key});

  @override
  State<JLPTListScreen> createState() => _JLPTListScreenState();
}

class _JLPTListScreenState extends State<JLPTListScreen> {
  String? _level;
  int page = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JLPTProvider>().loadExams(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện thi JLPT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JLPTPracticeScreen()),
              );
            },
          )
        ],
      ),
      body: Consumer<JLPTProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.exams.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildLevelChips(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      provider.loadExams(refresh: true, level: _level),
                  child: ListView.builder(
                    itemCount: provider.exams.length,
                    itemBuilder: (context, index) {
                      final exam = provider.exams[index];
                      return _ExamCard(exam: exam);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLevelChips() {
    const levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: _level == null,
            onSelected: (_) => _onLevel(null),
          ),
          ...levels.map((lv) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(lv),
                  selected: _level == lv,
                  onSelected: (_) => _onLevel(lv),
                ),
              )),
        ],
      ),
    );
  }

  void _onLevel(String? lv) {
    setState(() => _level = lv);
    context.read<JLPTProvider>().loadExams(refresh: true, level: lv);
  }
}

class _ExamCard extends StatelessWidget {
  final JLPTExamBrief exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(exam.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exam.description != null) Text(exam.description!),
            const SizedBox(height: 4),
            Text('Level: ${exam.level} | Thời gian: ${exam.timeLimit}p'),
            Text('Số câu: ${exam.totalQuestions} | Điểm: ${exam.totalScore}'),
            if (exam.lastResult != null)
              Text(
                  'Điểm gần nhất: ${exam.lastResult!.score} (${exam.lastResult!.isPassed ? 'Đỗ' : 'Trượt'})'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_forward_ios, size: 16),
            Text(exam.level,
                style:
                    TextStyle(color: AppTheme.getJlptLevelColor(exam.level))),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    JLPTExamScreen(examId: exam.id, title: exam.title)),
          );
        },
      ),
    );
  }
}
