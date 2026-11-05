import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/learning_goal.dart';
import '../services/goal_service.dart';

/// State của màn Mục tiêu học tập. Tạo cùng màn và huỷ khi rời màn, nên dữ
/// liệu không sống qua lần đăng xuất.
///
/// Sau mỗi lần tạo/sửa/xoá, danh sách tải lại ngầm (giữ dữ liệu đang hiện),
/// vì tiến độ và trạng thái hoàn thành do server tính.
class GoalProvider extends ChangeNotifier {
  GoalProvider({GoalService? service}) : _service = service ?? GoalService();

  final GoalService _service;

  ViewState<GoalsSnapshot> _state = const ViewState.idle();
  String? _message;
  int _generation = 0;
  bool _disposed = false;

  ViewState<GoalsSnapshot> get state => _state;

  /// Lỗi của thao tác xoá gần nhất, màn hình hiện một lần bằng snackbar.
  String? consumeMessage() {
    final message = _message;
    _message = null;
    return message;
  }

  /// Tải danh sách. Đang có dữ liệu thì giữ nguyên trong lúc tải lại (quay về
  /// sau khi học, làm mới), lỗi lúc đó chỉ báo qua thông điệp.
  Future<void> load() async {
    final generation = ++_generation;
    final hadData = _state.hasData;
    if (!hadData) {
      _state = const ViewState.loading();
      _notify();
    }

    final result = await ViewState.guard(_service.list);
    if (_disposed || generation != _generation) return;
    if (result case ViewFailure(:final message) when hadData) {
      _message = message;
    } else {
      _state = result;
    }
    _notify();
  }

  /// `null` khi đã tạo; ngược lại là thông điệp để form hiện ngay.
  Future<String?> create(GoalDraft draft) => _write(() => _service.create(draft));

  Future<String?> update(String id, GoalEdit edit) => _write(() => _service.update(id, edit));

  Future<void> delete(LearningGoal goal) async {
    final error = await _write(() => _service.delete(goal.id));
    if (error == null || _disposed) return;
    _message = error;
    _notify();
  }

  Future<String?> _write(Future<void> Function() action) async {
    final result = await ViewState.guard(action);
    if (result case ViewFailure(:final message)) return message;
    await load();
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
