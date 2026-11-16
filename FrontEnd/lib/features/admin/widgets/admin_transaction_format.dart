import '../models/admin_transaction.dart';

String formatTransactionCurrency(num amount) {
  final value = amount.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '$value đ';
}

String formatTransactionDate(DateTime? date) {
  if (date == null) return '—';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
}

String transactionPaymentIcon(String method) => switch (method) {
      'MOMO' => 'M',
      'VNPAY' => 'V',
      'BANK' => 'B',
      'CARD' => 'C',
      _ => '₫',
    };

/// Bước tiếp theo quản trị viên làm được với một giao dịch: `(trạng thái mới, nhãn)`.
List<(String, String)> transactionNextSteps(AdminTransaction transaction) => switch (transaction.status) {
      'pending' || 'processing' => const [('completed', 'Xác nhận'), ('failed', 'Từ chối')],
      'completed' => const [('refunded', 'Đánh dấu hoàn tiền')],
      _ => const [],
    };
