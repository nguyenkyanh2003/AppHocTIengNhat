import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vocabulary_provider.dart';
import '../../models/vocabulary.dart';
import '../../config/theme.dart';

class VocabularyDetailScreen extends StatefulWidget {
  final String vocabularyId;

  const VocabularyDetailScreen({
    Key? key,
    required this.vocabularyId,
  }) : super(key: key);

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<VocabularyProvider>()
          .loadVocabularyDetail(widget.vocabularyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<VocabularyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadVocabularyDetail(
                      widget.vocabularyId,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final vocab = provider.selectedVocabulary;
          if (vocab == null) {
            return const Center(child: Text('Không tìm thấy từ vựng'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(vocab),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildMainInfo(vocab),
                    if (vocab.usageContext != null) _buildUsageContext(vocab),
                    if (vocab.examples.isNotEmpty) _buildExamples(vocab),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// App bar gradient đẹp
  Widget _buildAppBar(Vocabulary vocab) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          vocab.word,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.9),
                AppTheme.primaryColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.school_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  /// Thông tin chính
  Widget _buildMainInfo(Vocabulary vocab) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Từ Kanji lớn
          Center(
            child: Text(
              vocab.word,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Hiragana
          Center(
            child: Text(
              vocab.hiragana,
              style: TextStyle(
                fontSize: 28,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          // Nghĩa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.translate,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nghĩa',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vocab.meaning,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Level
          if (vocab.level != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getLevelColor(vocab.level!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: _getLevelColor(vocab.level!),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cấp độ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getLevelColor(vocab.level!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vocab.level!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Ngữ cảnh sử dụng
  Widget _buildUsageContext(Vocabulary vocab) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngữ cảnh sử dụng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vocab.usageContext!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.amber[900],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ví dụ câu
  Widget _buildExamples(Vocabulary vocab) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.2),
                      Colors.purple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ví dụ câu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...vocab.examples.asMap().entries.map((entry) {
            final index = entry.key;
            final example = entry.value;
            return _buildExampleCard(index + 1, example);
          }),
        ],
      ),
    );
  }

  Widget _buildExampleCard(int number, VocabExample example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (example.audioUrl != null)
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.purple),
                  onPressed: () {
                    // TODO: Play audio
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            example.sentence,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            example.meaning,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
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
