String formatTransactionCurrency(num amount) {
  final value = amount.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '$value đ';
}

String formatTransactionDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String transactionPaymentIcon(dynamic method) => switch (method?.toString()) {
      'MOMO' => 'M',
      'VNPAY' => 'V',
      'BANK' => 'B',
      'CARD' => 'C',
      _ => '₫',
    };
