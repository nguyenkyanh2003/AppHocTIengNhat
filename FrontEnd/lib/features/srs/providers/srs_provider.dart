import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../models/srs_card.dart';
import '../models/srs_progress.dart';
import '../models/srs_tally.dart';
import '../services/srs_service.dart';

/// Phiên ôn tập SRS: hàng thẻ đến hạn, lật thẻ, tự đánh giá, bỏ qua, đặt lại,
/// xoá — và badge số thẻ đến hạn.
///
/// Hàng thẻ lấy theo **đợt**: làm hết đợt cục bộ rồi xin đợt kế tiếp kèm danh
/// sách thẻ đã xử lý trong phiên, để thẻ bỏ qua không chiếm chỗ của thẻ phía
/// sau (spec SRS §3.4). Thẻ chỉ vào danh sách đó khi **chắc** đã xử lý xong —
/// lỗi mạng hay lỗi máy chủ chưa rõ kết quả thì thẻ ở lại để thử lại.
class SrsProvider extends ChangeNotifier {
  SrsProvider({SrsService? service}) : _service = service ?? SrsService();

  final SrsService _service;

  /// Trần số thẻ xử lý trong một phiên — cũng là trần danh sách loại trừ mà
  /// server nhận. Đạt trần thì kết thúc phiên, mở phiên mới để ôn tiếp.
  static const int sessionLimit = 200;

  ViewState<List<SrsCard>> _session = const ViewState.idle();
  ViewState<SrsStats> _stats = const ViewState.idle();
  final Set<String> _handled = {};
  SrsTally _tally = const SrsTally();
  int? _dueCount;

  bool _revealed = false;
  bool _busy = false;
  String? _actionError;
  Future<void> Function()? _retryAction;
  String? _notice;

  /// Tăng mỗi lần mở phiên mới: đợt thẻ về muộn của phiên cũ bị bỏ.
  int _generation = 0;
  bool _disposed = false;

  /// Hàng thẻ còn lại của đợt hiện tại; thẻ đầu là thẻ đang ôn. Rỗng nghĩa là
  /// phiên đã kết thúc.
  ViewState<List<SrsCard>> get sessionState => _session;
  ViewState<SrsStats> get statsState => _stats;
  SrsCard? get currentCard {
    final cards = _session.valueOrNull;
    return cards == null || cards.isEmpty ? null : cards.first;
  }

  bool get isFinished => _session.valueOrNull?.isEmpty ?? false;
  bool get isRevealed => _revealed;
  bool get isBusy => _busy;
  SrsTally get tally => _tally;
  int get handledCount => _handled.length;

  /// Số từ đến hạn của toàn tài khoản, `null` khi chưa tải được lần nào.
  int? get dueCount => _dueCount;

  /// Lỗi của thao tác vừa rồi; thẻ vẫn giữ nguyên để [retry].
  String? get actionError => _actionError;

  /// Thông báo một lần (thẻ vừa bị đổi ở nơi khác...). Đọc xong thì xoá.
  String? consumeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> startSession() async {
    final generation = ++_generation;
    _handled.clear();
    _tally = const SrsTally();
    _stats = const ViewState.idle();
    _clearCardState();
    _session = const ViewState.loading();
    _notify();
    await _fetchNextBatch(generation);
  }

  /// Tải lại đợt thẻ sau khi lấy đợt bị lỗi, giữ nguyên số liệu phiên.
  Future<void> reloadBatch() async {
    final generation = _generation;
    _session = const ViewState.loading();
    _notify();
    await _fetchNextBatch(generation);
  }

  Future<void> loadDueCount() async {
    final result = await ViewState.guard(_service.fetchDueCount);
    // Badge lỗi thì giữ số cũ: một lần mất mạng không nên làm badge biến mất.
    if (result.valueOrNull != null) _dueCount = result.valueOrNull;
    _notify();
  }

  void reveal() {
    if (currentCard == null || _busy) return;
    _revealed = true;
    _notify();
  }

  /// Bỏ qua trong phiên: không đổi gì ở server, thẻ quay lại ở phiên sau.
  Future<void> skip() async {
    final card = currentCard;
    if (card == null || _busy) return;
    _tally = _tally.add(skipped: 1);
    await _finishCard(card);
  }

  Future<void> answer({required bool remembered}) => _mutate((card) async {
        await _service.review(
          itemId: card.itemId,
          isCorrect: remembered,
          expectedNextReview: card.progress.nextReview,
        );
        _tally = remembered ? _tally.add(remembered: 1) : _tally.add(forgotten: 1);
      });

  Future<void> resetCurrent() => _mutate((card) async {
        await _service.reset(itemId: card.itemId, expectedNextReview: card.progress.nextReview);
        _tally = _tally.add(reset: 1);
      });

  Future<void> removeCurrent() => _mutate((card) async {
        await _service.remove(itemId: card.itemId);
        _tally = _tally.add(removed: 1);
      });

  Future<void> retry() async => _retryAction?.call();

  /// Đặt lại lịch của một từ ngoài phiên ôn (màn chi tiết từ vựng), kể cả khi
  /// chưa đến hạn. Lỗi được ném lại để màn gọi tự báo.
  Future<SrsProgress> resetSchedule({
    required String itemId,
    required DateTime expectedNextReview,
  }) async {
    final progress = await _service.reset(itemId: itemId, expectedNextReview: expectedNextReview);
    await loadDueCount();
    return progress;
  }

  void clear() {
    _generation++;
    _handled.clear();
    _tally = const SrsTally();
    _session = const ViewState.idle();
    _stats = const ViewState.idle();
    _dueCount = null;
    _clearCardState();
    _notify();
  }

  // --- nội bộ ---------------------------------------------------------------

  void _clearCardState() {
    _revealed = false;
    _busy = false;
    _actionError = null;
    _retryAction = null;
    _notice = null;
  }

  /// Chạy một thao tác ghi trên thẻ đang ôn, khoá nút cho tới khi xong.
  ///
  /// Chỉ chuyển thẻ sau khi server trả lời rõ ràng. Lỗi mạng/máy chủ giữ thẻ
  /// và danh sách nguyên vẹn, kèm nút thử lại — không tự gửi lại.
  ///
  /// Bắt lỗi tại đây thay vì qua [ViewState.guard]: cách xử lý phụ thuộc mã
  /// lỗi (404, `SRS_NOT_DUE`...), mà guard chỉ giữ lại câu thông báo — và lỗi
  /// một thao tác không được thay cả phiên bằng [ViewFailure].
  Future<void> _mutate(Future<void> Function(SrsCard card) action) async {
    final card = currentCard;
    if (card == null || _busy) return;

    _busy = true;
    _actionError = null;
    _retryAction = null;
    _notify();

    try {
      await action(card);
      _busy = false;
      await _finishCard(card);
      await loadDueCount();
    } on ApiException catch (error) {
      _busy = false;
      await _handleRejection(card, error, () => _mutate(action));
    } catch (_) {
      _busy = false;
      _actionError = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      _retryAction = () => _mutate(action);
      _notify();
    }
  }

  /// Phân loại lỗi theo mã của server (spec SRS §3.5–3.6).
  Future<void> _handleRejection(
    SrsCard card,
    ApiException error,
    Future<void> Function() retry,
  ) async {
    final current = error.details?['current_progress'];

    if (error.statusCode == 404) {
      _notice = 'Từ này không còn trong lịch ôn.';
      await _finishCard(card);
    } else if (error.code == 'SRS_NOT_DUE') {
      _notice = 'Thẻ này vừa được ôn ở nơi khác và chưa đến hạn lại.';
      await _finishCard(card);
    } else if (error.code == 'SRS_PROGRESS_CHANGED' && current is Map) {
      // Vẫn đến hạn nhưng lịch đã đổi: nạp trạng thái mới, bắt chọn lại.
      _replaceCurrent(card.copyWith(
        progress: SrsProgress.fromJson(Map<String, dynamic>.from(current)),
      ));
      _notice = 'Lịch ôn của thẻ vừa thay đổi. Hãy lật thẻ và chọn lại.';
    } else if (error.code == 'ITEM_UNAVAILABLE') {
      _replaceCurrent(card.copyWith(unavailable: true));
      _notice = 'Nội dung của thẻ không còn tồn tại. Hãy bỏ qua hoặc xoá thẻ.';
    } else {
      _actionError = error.message;
      _retryAction = retry;
    }
    _notify();
  }

  void _replaceCurrent(SrsCard card) {
    final cards = [...?_session.valueOrNull];
    if (cards.isEmpty) return;
    cards[0] = card;
    _session = ViewState.data(cards);
    _revealed = false;
  }

  /// Thẻ đã xử lý xong: ghi vào danh sách loại trừ, sang thẻ kế, hết đợt thì
  /// xin đợt mới.
  Future<void> _finishCard(SrsCard card) async {
    _handled.add(card.itemId);
    _revealed = false;
    _actionError = null;
    _retryAction = null;

    final remaining = [...?_session.valueOrNull]..removeWhere((c) => c.itemId == card.itemId);
    _session = ViewState.data(remaining);
    _notify();
    if (remaining.isEmpty) await _fetchNextBatch(_generation);
  }

  Future<void> _fetchNextBatch(int generation) async {
    final room = sessionLimit - _handled.length;
    final result = room <= 0
        ? const ViewData<List<SrsCard>>([])
        : await ViewState.guard(() async => (await _service.fetchDue(
              excludeItemIds: _handled.toList(),
              limit: room < SrsService.defaultLimit ? room : SrsService.defaultLimit,
            ))
                .cards);
    if (generation != _generation || _disposed) return;

    _session = result;
    _notify();
    if (isFinished) await _loadSummary(generation);
  }

  /// Hết phiên: tải phân bố hộp và số thẻ còn đến hạn cho màn tóm tắt.
  Future<void> _loadSummary(int generation) async {
    _stats = const ViewState.loading();
    _notify();
    final stats = await ViewState.guard(_service.fetchStats);
    if (generation != _generation || _disposed) return;
    _stats = stats;
    if (stats.valueOrNull != null) _dueCount = stats.valueOrNull!.dueCount;
    _notify();
  }
}
