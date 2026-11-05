import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_group_provider.dart';

/// Hộp thoại tìm nhóm theo tên.
void showStudyGroupSearchDialog(BuildContext context,
    {required TextEditingController searchController,
    required void Function(String query) performSearch}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Tìm kiếm nhóm'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên nhóm...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            performSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              performSearch(searchController.text);
            },
            child: const Text('Tìm'),
          ),
        ],
      );
    },
  );
}

/// Hộp thoại lọc nhóm theo cấp độ.
void showStudyGroupFilterDialog(BuildContext context,
    {required TabController tabController}) {
  final provider = Provider.of<StudyGroupProvider>(context, listen: false);
  String? selectedLevel = provider.levelFilter;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Lọc nhóm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cấp độ:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['ALL', 'N5', 'N4', 'N3', 'N2', 'N1'].map((level) {
                    return ChoiceChip(
                      label: Text(level == 'ALL' ? 'Tất cả' : level),
                      selected: selectedLevel == level,
                      onSelected: (selected) {
                        setState(() {
                          selectedLevel = selected ? level : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  provider.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Xóa bộ lọc'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.setLevelFilter(selectedLevel);
                  Navigator.pop(context);
                  tabController.animateTo(1);
                },
                child: const Text('Áp dụng'),
              ),
            ],
          );
        },
      );
    },
  );
}
