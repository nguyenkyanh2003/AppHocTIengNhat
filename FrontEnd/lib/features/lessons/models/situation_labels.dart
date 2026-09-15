import 'package:flutter/material.dart';

/// Nhãn tiếng Việt và biểu tượng cho từng mã tình huống của backend.
///
/// Backend trả mã tiếng Anh (`supermarket`, `train`...) vì đó là khoá dữ liệu;
/// phần hiển thị nằm ở client. Mã lạ (tình huống mới thêm ở backend mà client
/// chưa cập nhật) vẫn hiện được nhờ [labelFor] trả lại chính mã đó.
const Map<String, ({String label, IconData icon})> kSituationLabels = {
  'self_introduction': (label: 'Tự giới thiệu', icon: Icons.waving_hand_outlined),
  'daily_life': (label: 'Sinh hoạt hằng ngày', icon: Icons.wb_sunny_outlined),
  'supermarket': (label: 'Đi siêu thị', icon: Icons.shopping_cart_outlined),
  'convenience_store': (label: 'Cửa hàng tiện lợi', icon: Icons.store_outlined),
  'train': (label: 'Đi tàu', icon: Icons.train_outlined),
  'bus': (label: 'Đi xe buýt', icon: Icons.directions_bus_outlined),
  'hospital': (label: 'Đi khám bệnh', icon: Icons.local_hospital_outlined),
  'pharmacy': (label: 'Hiệu thuốc', icon: Icons.medication_outlined),
  'city_hall': (label: 'Thủ tục hành chính', icon: Icons.account_balance_outlined),
  'bank': (label: 'Ngân hàng', icon: Icons.account_balance_wallet_outlined),
  'post_office': (label: 'Bưu điện', icon: Icons.local_post_office_outlined),
  'restaurant': (label: 'Ở nhà hàng', icon: Icons.restaurant_outlined),
  'school': (label: 'Ở trường học', icon: Icons.school_outlined),
  'part_time_job': (label: 'Việc làm thêm', icon: Icons.work_outline),
  'phone_call': (label: 'Gọi điện thoại', icon: Icons.phone_outlined),
  'real_estate': (label: 'Tìm thuê nhà', icon: Icons.home_work_outlined),
  'emergency': (label: 'Tình huống khẩn cấp', icon: Icons.emergency_outlined),
};

String situationLabel(String code) => kSituationLabels[code]?.label ?? code;

IconData situationIcon(String code) =>
    kSituationLabels[code]?.icon ?? Icons.place_outlined;
