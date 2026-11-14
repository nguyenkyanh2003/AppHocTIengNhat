import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/kanji.dart';
import '../services/kanji_service.dart';

/// Chi tiết một chữ Kanji và nút thêm/gỡ khỏi lịch ôn.
///
/// Tạo cùng màn chi tiết và huỷ khi rời màn: trạng thái "đã thêm" là của
/// người đang xem, không nên sống tiếp sang lượt đăng nhập khác.
class KanjiDetailProvider extends ChangeNotifier {
  KanjiDetailProvider({KanjiService? service}) : _service = service ?? KanjiService();

  final KanjiService _service;

  ViewState<Kanji> _detail = const ViewState.idle();
  bool _saving = false;
  bool _disposed = false;

  ViewState<Kanji> get detailState => _detail;
  Kanji? get kanji => _detail.valueOrNull;
  bool get isSaving => _saving;

  Future<void> load(String id) async {
    _detail = const ViewState.loading();
    _notify();
    _detail = await ViewState.guard(() => _service.detail(id));
    _notify();
  }

  /// Thêm vào lịch ôn nếu chưa có, gỡ ra nếu đã có. Trả câu lỗi để màn hình
  /// báo, `null` khi thành công. Lỗi thì giữ nguyên trạng thái đang hiện.
  Future<String?> toggleReview() async {
    final current = kanji;
    if (current == null || _saving) return null;

    _saving = true;
    _notify();
    final result = await ViewState.guard(() async {
      if (!current.isInReview) return current.withSrsProgress(await _service.addToReview(current.id));
      await _service.removeFromReview(current.id);
      return current.withSrsProgress(null);
    });
    if (result.hasData) _detail = result;
    _saving = false;
    _notify();
    return result.errorOrNull;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
