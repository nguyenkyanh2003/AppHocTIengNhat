import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/study_group_provider.dart';
import '../../providers/auth_provider.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class StudyGroupListScreen extends StatefulWidget {
  const StudyGroupListScreen({Key? key}) : super(key: key);

  @override
  State<StudyGroupListScreen> createState() => _StudyGroupListScreenState();
}

class _StudyGroupListScreenState extends State<StudyGroupListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudyGroupProvider>(context, listen: false);
      provider.loadMyGroups();
      provider.loadAllGroups(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_tabController.index == 1) {
        final provider =
            Provider.of<StudyGroupProvider>(context, listen: false);
        if (!provider.isLoading && provider.hasMore) {
          provider.loadAllGroups();
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm học'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[700],
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              indicator: BoxDecoration(
                color: Colors.blue[50],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.blue[700]!,
                    width: 3,
                  ),
                ),
              ),
              tabs: const [
                Tab(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 22),
                      SizedBox(height: 4),
                      Text('Nhóm của tôi'),
                    ],
                  ),
                ),
                Tab(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, size: 22),
                      SizedBox(height: 4),
                      Text('Khám phá'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroupsTab(),
          _buildAllGroupsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateGroupScreen(),
            ),
          ).then((created) {
            if (created == true) {
              final provider =
                  Provider.of<StudyGroupProvider>(context, listen: false);
              provider.loadMyGroups();
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo nhóm'),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return Consumer<StudyGroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.myGroups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Bạn chưa tham gia nhóm nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.explore),
                  label: const Text('Khám phá nhóm'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.loadMyGroups,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.myGroups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(provider.myGroups[index], true);
            },
          ),
        );
      },
    );
  }

  Widget _buildAllGroupsTab() {
    return Consumer<StudyGroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.allGroups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.allGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  provider.searchQuery != null
                      ? 'Không tìm thấy nhóm phù hợp'
                      : 'Chưa có nhóm nào',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAllGroups(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: provider.allGroups.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.allGroups.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _buildGroupCard(provider.allGroups[index], false);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(group, bool isMyGroup) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id;
    final isMember = currentUserId != null && group.isMember(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(groupId: group.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar lớn hơn
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(group.avatar ?? ''),
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.isPrivate)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.orange[700],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    group.levelDisplay,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.people, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              group.memberCountDisplay,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMember)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _joinGroup(group.id),
                        tooltip: 'Tham gia',
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Đã tham gia',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (group.description != null && group.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _joinGroup(String groupId) async {
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    final success = await provider.joinGroup(groupId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tham gia nhóm thành công!')),
      );
      provider.loadAllGroups(refresh: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Lỗi khi tham gia nhóm')),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tìm kiếm nhóm'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Nhập tên nhóm...',
              prefixIcon: Icon(Icons.search),
            ),
            autofocus: true,
            onSubmitted: (value) {
              Navigator.pop(context);
              _performSearch(value);
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
                _performSearch(_searchController.text);
              },
              child: const Text('Tìm'),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(String query) {
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    provider.setSearchQuery(query.isEmpty ? null : query);
    _tabController.animateTo(1);
  }

  void _showFilterDialog() {
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
                    _tabController.animateTo(1);
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
}
