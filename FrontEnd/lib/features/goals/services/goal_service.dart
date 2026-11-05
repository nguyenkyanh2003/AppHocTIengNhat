import '../../../core/network/api_client.dart';
import '../models/learning_goal.dart';

/// Mục tiêu học tập của người đang đăng nhập. Không đặt `cache`: tiến độ đổi
/// sau mỗi lần học. Lỗi được ném ra để màn hình hiện đúng thông điệp server.
class GoalService {
  final ApiClient _apiClient = ApiClient();

  Future<GoalsSnapshot> list() async {
    final response = await _apiClient.get('/goal');
    return GoalsSnapshot(
      goals: (response['data'] as List? ?? const [])
          .map((item) => LearningGoal.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
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
    return LearningGoal.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<LearningGoal> update(String id, GoalEdit edit) async {
    final deadline = edit.deadline;
    final response = await _apiClient.patch('/goal/$id', {
      'title': edit.title.trim(),
      if (edit.target != null) 'target': edit.target,
      'deadline': deadline == null ? null : dateKey(deadline),
    });
    return LearningGoal.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/goal/$id');
  }
}
