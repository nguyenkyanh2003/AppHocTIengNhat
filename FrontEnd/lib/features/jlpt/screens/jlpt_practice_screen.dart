import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jlpt_practice_provider.dart';

class JLPTPracticeScreen extends StatefulWidget {
  const JLPTPracticeScreen({super.key});

  @override
  State<JLPTPracticeScreen> createState() => _JLPTPracticeScreenState();
}

class _JLPTPracticeScreenState extends State<JLPTPracticeScreen> {
  String type = 'moji_goi';
  String? level;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<JLPTPracticeProvider>()
          .loadPractice(type: type, level: level);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện nhanh')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<JLPTPracticeProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.items.isEmpty) {
                  return const Center(child: Text('Chưa có câu hỏi'));
                }
                return ListView.builder(
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final item = provider.items[index] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(item['question_text'] ?? ''),
                      subtitle: Text((item['choices'] as List<dynamic>? ?? [])
                          .join(' | ')),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const skills = [
      {'key': 'moji_goi', 'label': 'Từ vựng'},
      {'key': 'bunpou', 'label': 'Ngữ pháp'},
      {'key': 'dokkai', 'label': 'Đọc'},
      {'key': 'choukai', 'label': 'Nghe'},
    ];
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          DropdownButton<String>(
            value: type,
            items: skills
                .map((s) => DropdownMenuItem(
                    value: s['key']!, child: Text(s['label']!)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => type = v);
              context
                  .read<JLPTPracticeProvider>()
                  .loadPractice(type: type, level: level);
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<String?>(
            value: level,
            hint: const Text('Level'),
            items: [null, 'N5', 'N4', 'N3', 'N2', 'N1']
                .map((lv) =>
                    DropdownMenuItem(value: lv, child: Text(lv ?? 'Tất cả')))
                .toList(),
            onChanged: (v) {
              setState(() => level = v);
              context
                  .read<JLPTPracticeProvider>()
                  .loadPractice(type: type, level: level);
            },
          ),
        ],
      ),
    );
  }
}
