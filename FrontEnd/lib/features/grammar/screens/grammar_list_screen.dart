import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grammar_provider.dart';
import './grammar_detail_screen.dart';

class GrammarListScreen extends StatefulWidget {
  final String? level;

  const GrammarListScreen({Key? key, this.level}) : super(key: key);

  @override
  State<GrammarListScreen> createState() => _GrammarListScreenState();
}

class _GrammarListScreenState extends State<GrammarListScreen> {
  late TextEditingController _searchController;
  String? _selectedLevel;
  String? _selectedSort = 'popular';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedLevel = widget.level ?? 'N5';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGrammars();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadGrammars() {
    final provider = Provider.of<GrammarProvider>(context, listen: false);
    if (_searchController.text.isNotEmpty) {
      provider.searchGrammars(_searchController.text);
    } else {
      provider.loadGrammars(
        level: _selectedLevel,
        sortBy: _selectedSort,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngữ Pháp'),
        elevation: 0,
      ),
      body: Consumer<GrammarProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Search & Filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm ngữ pháp...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadGrammars();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        if (value.isEmpty) {
                          _loadGrammars();
                        } else {
                          provider.searchGrammars(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Level & Sort filters
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedLevel,
                            isExpanded: true,
                            items: ['N5', 'N4', 'N3', 'N2', 'N1']
                                .map((level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(level),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedLevel = value);
                              _loadGrammars();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedSort,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'popular',
                                child: Text('Phổ biến'),
                              ),
                              DropdownMenuItem(
                                value: 'newest',
                                child: Text('Mới nhất'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSort = value);
                              _loadGrammars();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(provider.error ?? ''),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _loadGrammars,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : provider.grammars.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox,
                                        size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Không tìm thấy ngữ pháp'),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: provider.grammars.length,
                                itemBuilder: (context, index) {
                                  final grammar = provider.grammars[index];
                                  return GrammarCard(
                                    grammar: grammar,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              GrammarDetailScreen(
                                                  grammarId: grammar.id),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class GrammarCard extends StatelessWidget {
  final dynamic grammar;
  final VoidCallback onTap;

  const GrammarCard({
    Key? key,
    required this.grammar,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getLevelColor(grammar.level),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              grammar.level,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          grammar.title ?? grammar.pattern ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          grammar.meaning ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility_outlined, size: 18, color: Colors.grey),
            Text(
              '${grammar.viewCount ?? 0}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
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
        return Colors.red;
      case 'N1':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
