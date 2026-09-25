/// Khoá ngày và giờ Việt Nam phía client.
///
/// Việt Nam giữ cố định UTC+7, không có giờ mùa hè, nên đổi giờ chỉ là một phép
/// cộng — không cần dữ liệu múi giờ, và kết quả không đổi theo máy đang chạy.
/// Khoá `YYYY-MM-DD` ở đây phải khớp cách server tính (`streak-rules.js#dayKey`),
/// vì client dùng nó để so với `last_activity_day` và ngày trong lịch.
library;

const vietnamOffset = Duration(hours: 7);

/// Đồng hồ treo tường Việt Nam, biểu diễn bằng một `DateTime` UTC đã cộng 7
/// giờ: đọc `year/month/day/hour/minute` của nó là ra giờ Việt Nam.
DateTime vietnamWallClock(DateTime instant) => instant.toUtc().add(vietnamOffset);

String _two(int value) => value.toString().padLeft(2, '0');

/// Khoá `YYYY-MM-DD` của một đồng hồ treo tường (chỉ lấy phần ngày).
String dayKeyOf(DateTime wallClock) =>
    '${wallClock.year.toString().padLeft(4, '0')}-${_two(wallClock.month)}-${_two(wallClock.day)}';

/// Khoá ngày Việt Nam của một thời điểm.
String vietnamDayKey(DateTime instant) => dayKeyOf(vietnamWallClock(instant));

/// `2026-09-26` → ngày UTC cùng năm/tháng/ngày, để làm phép cộng ngày.
DateTime parseDayKey(String key) => DateTime.utc(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(5, 7)),
      int.parse(key.substring(8, 10)),
    );

/// Cộng [days] ngày lịch vào khoá ngày.
String addDaysToKey(String key, int days) {
  final date = parseDayKey(key);
  return dayKeyOf(DateTime.utc(date.year, date.month, date.day + days));
}

/// `2026-09-26` → `26/09`, cho câu chữ ngắn gọn trên màn hình.
String formatDayKey(String key) {
  final parts = key.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}' : key;
}
