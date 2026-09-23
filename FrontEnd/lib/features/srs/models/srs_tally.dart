/// Số liệu của **một phiên ôn**, chỉ nằm ở client.
///
/// Không phải lịch sử nhiều ngày: số liệu nhiều ngày đọc từ nhật ký hoạt động
/// ở server (spec SRS §7). Thẻ bị xung đột (409) không được tính là đã trả lời.
class SrsTally {
  const SrsTally({
    this.remembered = 0,
    this.forgotten = 0,
    this.skipped = 0,
    this.reset = 0,
    this.removed = 0,
  });

  final int remembered;
  final int forgotten;
  final int skipped;
  final int reset;
  final int removed;

  int get answered => remembered + forgotten;

  bool get isEmpty => answered + skipped + reset + removed == 0;

  SrsTally add({
    int remembered = 0,
    int forgotten = 0,
    int skipped = 0,
    int reset = 0,
    int removed = 0,
  }) =>
      SrsTally(
        remembered: this.remembered + remembered,
        forgotten: this.forgotten + forgotten,
        skipped: this.skipped + skipped,
        reset: this.reset + reset,
        removed: this.removed + removed,
      );
}
