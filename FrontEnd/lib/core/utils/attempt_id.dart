import 'dart:math';

/// Định danh một **lượt làm bài**, sinh khi người học bắt đầu làm.
///
/// Server dùng nó để phân biệt "gửi lại bài cũ" với "làm lại lần mới": gửi lại
/// đúng ID cũ thì nhận lại kết quả đã chấm, không bị cộng XP lần hai; làm lại
/// thì phải là ID mới. Vì vậy ID phải được giữ nguyên suốt một lượt, kể cả khi
/// request đầu hỏng vì mất mạng, và chỉ đổi khi bắt đầu lượt khác.
///
/// Dạng UUID phiên bản 4, đúng thứ server kiểm.
String newAttemptId([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));

  // Bốn bit phiên bản (4) và hai bit biến thể (10) theo RFC 4122.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
      '-${hex.substring(16, 20)}-${hex.substring(20)}';
}
