import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/learning_goal.dart';

/// Mục tiêu học tập của người đang đăng nhập. Không đặt `cache`: tiến độ đổi
/// sau mỗi lần học. Lỗi được ném ra để màn hình hiện đúng thông điệp server.
class GoalService {
  GoalService({ApiClient? client}) : _apiClient = client ?? ApiClient();

  final ApiClient _apiClient;

  /// `{ data, total, counts, available }`: danh sách kèm số đếm để form gợi ý
  /// mục tiêu (trường thêm có chú thích ở controller backend).
  Future<GoalsSnapshot> list() async {
    final response = await _apiClient.get('/goal');
    return GoalsSnapshot(
      goals: listOf(response, LearningGoal.fromJson),
      counts: GoalCounts.fromJson(Map<String, dynamic>.from(response['counts'] as Map? ?? const {})),
      available: GoalAvailability.fromJson(Map<String, dynamic>.from(response['available'] as Map? ?? const {})),
    );
  }

  Future<LearningGoal> create(GoalDraft draft) async {
    final title = draft.title?.trim() ?? '';
    final deadline = draft.deadline;
    final response = await _apiClient.post('/goal', {
      'type': draft.type.key,
      'target': draft.target,
      if (title.isNotEmpty) 'title': title,
      'deadline': deadline == null ? null : dateKey(deadline),
    });
    return objectOf(response, LearningGoal.fromJson);
  }

  Future<LearningGoal> update(String id, GoalEdit edit) async {
    final deadline = edit.deadline;
    final response = await _apiClient.patch('/goal/$id', {
      'title': edit.title.trim(),
      if (edit.target != null) 'target': edit.target,
      'deadline': deadline == null ? null : dateKey(deadline),
    });
    return objectOf(response, LearningGoal.fromJson);
  }

  Future<void> delete(String id) => _apiClient.delete('/goal/$id');
}
