/**
 * Danh mục tình huống thực tế cho bài học, lấy cảm hứng từ cách tổ chức nội
 * dung theo tình huống của Tsunagaru (tsunagarujp.mext.go.jp) — độc lập với
 * cấp độ JLPT. Đây là điểm mở rộng: thêm giá trị mới chỉ là sửa mảng này,
 * không cần migration vì field trên Lesson là optional.
 */
export const SITUATIONS = Object.freeze([
  'self_introduction', // tự giới thiệu, gặp người mới
  'daily_life', // sinh hoạt hằng ngày
  'supermarket', // đi siêu thị
  'convenience_store', // cửa hàng tiện lợi
  'shopping', // mua sắm ở cửa hàng: hỏi quầy, chọn đồ, mặc thử
  'directions', // hỏi đường
  'train', // đi tàu/ga tàu
  'bus', // đi xe buýt
  'hospital', // đi khám bệnh
  'pharmacy', // hiệu thuốc
  'city_hall', // làm giấy tờ hành chính (phường/quận)
  'bank', // ngân hàng
  'post_office', // bưu điện
  'restaurant', // nhà hàng/quán ăn
  'school', // trường học/lớp học
  'part_time_job', // công việc làm thêm
  'workplace', // ở nơi làm việc: dùng máy móc, hỏi đồng nghiệp
  'neighborhood', // sống trong khu dân cư: đổ rác, quy tắc chung
  'phone_call', // gọi điện thoại
  'real_estate', // tìm/thuê nhà
  'emergency', // tình huống khẩn cấp/thiên tai
]);

export default SITUATIONS;
