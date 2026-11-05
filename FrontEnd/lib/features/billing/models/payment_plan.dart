class PaymentPlan {
  final String id;
  final String name;
  final String price;
  final int amount;
  final String icon;
  final List<String> features;
  final bool recommended;

  PaymentPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.amount,
    required this.icon,
    required this.features,
    this.recommended = false,
  });
}

final List<PaymentPlan> paymentPlans = [
  PaymentPlan(
    id: 'basic',
    name: 'Gói Cơ Bản',
    price: 'Miễn phí',
    amount: 0,
    icon: '🎓',
    features: [
      'Học 5 bài miễn phí',
      'Từ vựng cơ bản',
      'Các bài tập giới hạn',
      'Xem tin tức',
    ],
  ),
  PaymentPlan(
    id: 'pro',
    name: 'Gói Pro',
    price: '79,000đ/tháng',
    amount: 79000,
    icon: '⭐',
    features: [
      'Truy cập không giới hạn',
      'Tất cả bài học & kanji',
      'Bài tập nâng cao',
      'Luyện thi JLPT đầy đủ',
      'Xóa quảng cáo',
      'Hỗ trợ ưu tiên',
    ],
    recommended: true,
  ),
  PaymentPlan(
    id: 'premium',
    name: 'Gói Premium',
    price: '199,000đ/năm',
    amount: 199000,
    icon: '💎',
    features: [
      'Tất cả tính năng Pro',
      'Giảm giá 50% so với tháng',
      'Lịch sử chi tiết',
      'Export dữ liệu',
      'Hỗ trợ 24/7',
    ],
  ),
];
