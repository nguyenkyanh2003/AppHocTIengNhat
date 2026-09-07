import 'package:flutter/material.dart';

class LearningGoal {
  final String id;
  final String title;
  final String description;
  final int targetValue; // số bài, từ vựng, etc.
  final int currentValue;
  final String type; // 'lessons', 'vocabulary', 'kanji', 'days'
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isCompleted;

  LearningGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.type,
    required this.createdAt,
    this.deadline,
    this.isCompleted = false,
  });

  double get progress => currentValue / targetValue;

  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetValue: json['target_value'] ?? 0,
      currentValue: json['current_value'] ?? 0,
      type: json['type'] ?? 'lessons',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'type': type,
      'deadline': deadline?.toIso8601String(),
    };
  }
}

class LearningGoalsScreen extends StatefulWidget {
  const LearningGoalsScreen({Key? key}) : super(key: key);

  @override
  State<LearningGoalsScreen> createState() => _LearningGoalsScreenState();
}

class _LearningGoalsScreenState extends State<LearningGoalsScreen> {
  List<LearningGoal> goals = [
    LearningGoal(
      id: '1',
      title: 'Hoàn Thành N5 Kanji',
      description: 'Học 103 kanji cấp N5',
      targetValue: 103,
      currentValue: 67,
      type: 'kanji',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      deadline: DateTime.now().add(const Duration(days: 30)),
      isCompleted: false,
    ),
    LearningGoal(
      id: '2',
      title: 'Streak 30 Ngày',
      description: 'Học liên tiếp 30 ngày',
      targetValue: 30,
      currentValue: 15,
      type: 'days',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      deadline: DateTime.now().add(const Duration(days: 15)),
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục Tiêu Học Tập'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Overall progress
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.8),
                    Colors.purple.withValues(alpha: 0.8)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tiến Độ Chung',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(goals.where((g) => g.isCompleted).length)}/${goals.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'mục tiêu đạt được',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Goals list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Các Mục Tiêu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddGoalDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...goals.map((goal) => _buildGoalCard(goal)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(LearningGoal goal) {
    final isExpired =
        goal.deadline != null && goal.deadline!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✓ Hoàn thành',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.progress == 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue}/${goal.targetValue}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (goal.deadline != null)
                  Text(
                    isExpired
                        ? 'Hết hạn'
                        : 'Hạn: ${_formatDeadline(goal.deadline!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        final index = goals.indexOf(goal);
                        if (goal.currentValue < goal.targetValue) {
                          goals[index] = LearningGoal(
                            id: goal.id,
                            title: goal.title,
                            description: goal.description,
                            targetValue: goal.targetValue,
                            currentValue: goal.currentValue + 1,
                            type: goal.type,
                            createdAt: goal.createdAt,
                            deadline: goal.deadline,
                            isCompleted:
                                goal.currentValue + 1 >= goal.targetValue,
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Cập Nhật'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => goals.remove(goal));
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Xóa'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();
    String selectedType = 'lessons';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Mục Tiêu Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mục tiêu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'lessons', child: Text('Bài học')),
                  DropdownMenuItem(value: 'vocabulary', child: Text('Từ vựng')),
                  DropdownMenuItem(value: 'kanji', child: Text('Kanji')),
                  DropdownMenuItem(value: 'days', child: Text('Ngày')),
                ],
                onChanged: (value) {
                  selectedType = value ?? 'lessons';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  targetController.text.isNotEmpty) {
                setState(() {
                  goals.add(
                    LearningGoal(
                      id: DateTime.now().toString(),
                      title: titleController.text,
                      description: descriptionController.text,
                      targetValue: int.parse(targetController.text),
                      currentValue: 0,
                      type: selectedType,
                      createdAt: DateTime.now(),
                      deadline: DateTime.now().add(const Duration(days: 30)),
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 'Hết hạn';
    if (daysLeft == 0) return 'Hôm nay';
    if (daysLeft == 1) return 'Ngày mai';
    return 'Còn $daysLeft ngày';
  }
}
