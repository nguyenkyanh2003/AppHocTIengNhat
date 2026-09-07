import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminAchievementManagementScreen extends StatefulWidget {
  const AdminAchievementManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminAchievementManagementScreen> createState() =>
      _AdminAchievementManagementScreenState();
}

class _AdminAchievementManagementScreenState
    extends State<AdminAchievementManagementScreen> {
  String _selectedRarity = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Achievements'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminProvider>().loadAchievements(),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final allAchievements = adminProvider.achievements;

          final filteredAchievements = _selectedRarity == 'all'
              ? allAchievements
              : allAchievements
                  .where((a) => a['rarity'] == _selectedRarity)
                  .toList();

          return Column(
            children: [
              // Stats Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                        '${allAchievements.length}', 'Tổng', Colors.blue),
                    _buildStatCard(
                      _getTotalUnlocked(allAchievements).toString(),
                      'Đã mở khóa',
                      Colors.green,
                    ),
                    _buildStatCard(
                      _getTotalXP(allAchievements).toString(),
                      'XP thưởng',
                      Colors.purple,
                    ),
                  ],
                ),
              ),

              // Rarity Filter
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRarityChip('Tất cả', 'all', Colors.grey),
                      _buildRarityChip('Common', 'common', Colors.grey),
                      _buildRarityChip('Rare', 'rare', Colors.blue),
                      _buildRarityChip('Epic', 'epic', Colors.purple),
                      _buildRarityChip('Legendary', 'legendary', Colors.orange),
                    ],
                  ),
                ),
              ),

              // Achievements List
              Expanded(
                child: adminProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredAchievements.isEmpty
                        ? const Center(child: Text('Không có achievements nào'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAchievements.length,
                            itemBuilder: (context, index) {
                              final achievement = filteredAchievements[index];
                              return _buildAchievementCard(achievement);
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Achievement'),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRarityChip(String label, String value, Color color) {
    final isSelected = _selectedRarity == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedRarity = value);
        },
        selectedColor: color.withValues(alpha: 0.3),
        backgroundColor: color.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final rarityColor = _getRarityColor(achievement['rarity']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rarityColor.withValues(alpha: 0.1),
              rarityColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rarityColor, width: 2),
            ),
            child: Center(
              child: Text(
                achievement['icon'],
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  achievement['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildRarityBadge(achievement['rarity']),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(achievement['description']),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⭐ ${achievement['xp']} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${achievement['unlocked']} người đã mở',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điều kiện mở khóa:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(achievement['condition']),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showEditDialog(achievement),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Chỉnh sửa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _duplicateAchievement(achievement),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Nhân bản'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteAchievement(achievement),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge(String rarity) {
    final color = _getRarityColor(rarity);
    final label = _getRarityLabel(rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRarityLabel(String rarity) {
    switch (rarity) {
      case 'common':
        return 'COMMON';
      case 'rare':
        return 'RARE';
      case 'epic':
        return 'EPIC';
      case 'legendary':
        return 'LEGENDARY';
      default:
        return rarity.toUpperCase();
    }
  }

  int _getTotalUnlocked(List<Map<String, dynamic>> achievements) {
    return achievements.fold<int>(
      0,
      (sum, item) => sum + ((item['unlocked'] ?? 0) as int),
    );
  }

  int _getTotalXP(List<Map<String, dynamic>> achievements) {
    return achievements.fold<int>(
      0,
      (sum, item) => sum + ((item['xp'] ?? 0) as int),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final iconController = TextEditingController();
    final xpController = TextEditingController();
    final conditionController = TextEditingController();
    String selectedRarity = 'common';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Achievement Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên achievement',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (emoji)',
                  border: OutlineInputBorder(),
                  hintText: '🎯',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: xpController,
                decoration: const InputDecoration(
                  labelText: 'XP thưởng',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRarity,
                decoration: const InputDecoration(
                  labelText: 'Độ hiếm',
                  border: OutlineInputBorder(),
                ),
                items: ['common', 'rare', 'epic', 'legendary']
                    .map((rarity) => DropdownMenuItem(
                          value: rarity,
                          child: Text(_getRarityLabel(rarity)),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedRarity = value!;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conditionController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng cần đạt',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.createAchievement({
                'name': nameController.text,
                'description': descController.text,
                'icon': iconController.text,
                'xp': int.tryParse(xpController.text) ?? 0,
                'rarity': selectedRarity,
                'condition': conditionController.text,
              });

              if (mounted && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'Đã thêm achievement mới!' : 'Lỗi khi thêm!'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> achievement) {
    final nameController = TextEditingController(text: achievement['name']);
    final descController =
        TextEditingController(text: achievement['description']);
    final iconController = TextEditingController(text: achievement['icon']);
    final xpController =
        TextEditingController(text: '${achievement['xp'] ?? 0}');
    final conditionController =
        TextEditingController(text: '${achievement['condition'] ?? 1}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh Sửa Achievement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên achievement',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (emoji)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: xpController,
                decoration: const InputDecoration(
                  labelText: 'XP thưởng',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conditionController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng cần đạt',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              final id = achievement['id'] ?? achievement['_id'];
              final success = await adminProvider.updateAchievement(id, {
                'name': nameController.text,
                'description': descController.text,
                'icon': iconController.text,
                'xp': int.tryParse(xpController.text) ?? 0,
                'condition': conditionController.text,
                'category': achievement['category'],
                'requirement_type': achievement['requirement_type'],
                'rarity': achievement['rarity'],
              });

              if (mounted && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content:
                        Text(success ? 'Đã cập nhật!' : 'Lỗi khi cập nhật!'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _duplicateAchievement(Map<String, dynamic> achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã nhân bản achievement!')),
    );
  }

  void _deleteAchievement(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa achievement "${achievement['name']}"?\n\n'
          '${achievement['unlocked'] ?? 0} người dùng đã mở khóa achievement này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              final id = achievement['id'] ?? achievement['_id'];
              final success = await adminProvider.deleteAchievement(id);

              if (mounted && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content:
                        Text(success ? 'Đã xóa achievement!' : 'Lỗi khi xóa!'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
