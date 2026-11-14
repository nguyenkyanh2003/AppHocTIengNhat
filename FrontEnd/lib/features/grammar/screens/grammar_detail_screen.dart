import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/grammar.dart';
import '../providers/grammar_provider.dart';
import '../widgets/grammar_detail_body.dart';

class GrammarDetailScreen extends StatefulWidget {
  const GrammarDetailScreen({super.key, required this.grammarId});

  final String grammarId;

  @override
  State<GrammarDetailScreen> createState() => _GrammarDetailScreenState();
}

class _GrammarDetailScreenState extends State<GrammarDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadAfterFrame();
  }

  /// Cùng route chỉ đổi mã (sửa địa chỉ trên web) thì màn được dùng lại,
  /// `initState` không chạy lần nữa: phải tự tải ngữ pháp mới.
  @override
  void didUpdateWidget(covariant GrammarDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grammarId != widget.grammarId) _loadAfterFrame();
  }

  /// Sau khung hình: đang dựng cây thì provider chưa được phép báo thay đổi.
  void _loadAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context.read<GrammarProvider>().loadDetail(widget.grammarId);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ngữ Pháp',
      body: ContentWidthLimit(
        child: AsyncView<Grammar>(
          state: context.watch<GrammarProvider>().detailState,
          onRetry: _load,
          builder: (context, grammar) => GrammarDetailBody(grammar: grammar),
        ),
      ),
    );
  }
}
