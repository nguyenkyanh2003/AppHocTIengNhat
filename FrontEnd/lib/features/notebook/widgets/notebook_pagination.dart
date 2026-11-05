import 'package:flutter/material.dart';
import '../providers/notebook_provider.dart';
import '../../../app/theme/app_tokens.dart';

/// Nút chuyển trang của sổ tay.
class NotebookPagination extends StatelessWidget {
  const NotebookPagination({
    super.key,
    required this.provider,
  });

  final NotebookProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: provider.hasPrevPage ? provider.previousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          Text(
            'Trang ${provider.currentPage}/${provider.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          ElevatedButton.icon(
            onPressed: provider.hasNextPage ? provider.nextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
            style: ElevatedButton.styleFrom(
              iconColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
