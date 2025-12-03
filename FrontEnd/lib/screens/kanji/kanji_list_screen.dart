import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kanji_provider.dart';

class KanjiListScreen extends StatefulWidget {
  const KanjiListScreen({Key? key}) : super(key: key);

  @override
  State<KanjiListScreen> createState() => _KanjiListScreenState();
}

class _KanjiListScreenState extends State<KanjiListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _levels = ['Tất cả', 'N5', 'N4', 'N3', 'N2', 'N1'];
  String _selectedLevel = 'Tất cả';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KanjiProvider>().loadKanjis(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildLevelFilter(),
              Expanded(child: _buildKanjiList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kanji',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  'Chữ Hán cơ bản',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm Kanji...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6C757D)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF6C757D)),
                    onPressed: () {
                      _searchController.clear();
                      context.read<KanjiProvider>().loadKanjis(refresh: true);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isEmpty) {
              context.read<KanjiProvider>().loadKanjis(refresh: true);
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              context.read<KanjiProvider>().searchKanjis(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLevelFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = level == _selectedLevel;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(level),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedLevel = level;
                });
                context.read<KanjiProvider>().filterByLevel(
                      level == 'Tất cả' ? null : level,
                    );
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFF6B6B).withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF6B6B) : const Color(0xFF6C757D),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKanjiList() {
    return Consumer<KanjiProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
            ),
          );
        }

        if (provider.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage,
                  style: const TextStyle(color: Color(0xFF6C757D)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadKanjis(refresh: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.kanjis.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy Kanji nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: provider.kanjis.length,
                itemBuilder: (context, index) {
                  return _buildKanjiCard(provider.kanjis[index]);
                },
              ),
            ),
            _buildPagination(provider),
          ],
        );
      },
    );
  }

  Widget _buildKanjiCard(kanji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/kanji-detail',
              arguments: kanji.id,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Kanji character với gradient background
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      kanji.character,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.hanviet != null)
                        Text(
                          kanji.hanviet!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (kanji.meaning != null)
                        Text(
                          kanji.meaning!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (kanji.onyomi.isNotEmpty)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Âm Hán: ${kanji.onyomi.join(", ")}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          if (kanji.onyomi.isNotEmpty && kanji.kunyomi.isNotEmpty)
                            const SizedBox(width: 8),
                          if (kanji.kunyomi.isNotEmpty)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Âm Kun: ${kanji.kunyomi.join(", ")}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Level badge
                if (kanji.level != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(kanji.level!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kanji.level!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(KanjiProvider provider) {
    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: provider.hasPreviousPage
                ? () => provider.previousPage()
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Text(
            'Trang ${provider.currentPage}/${provider.totalPages}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          ElevatedButton.icon(
            onPressed:
                provider.hasNextPage ? () => provider.nextPage() : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'N5':
        return Colors.green;
      case 'N4':
        return Colors.blue;
      case 'N3':
        return Colors.orange;
      case 'N2':
        return Colors.deepOrange;
      case 'N1':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
