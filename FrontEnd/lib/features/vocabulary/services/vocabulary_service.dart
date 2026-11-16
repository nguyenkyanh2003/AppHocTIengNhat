import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/vocabulary.dart';
import '../models/vocabulary_set.dart';

/// Một trang từ vựng trả về từ API.
typedef VocabularyPage = Paged<Vocabulary>;

class VocabularyService {
  VocabularyService({ApiClient? client}) : _apiClient = client ?? ApiClient();

  final ApiClient _apiClient;

  /// Danh sách từ vựng có phân trang và bộ lọc.
  Future<VocabularyPage> getVocabularies({
    int page = 1,
    int limit = 20,
    String? level,
    String? studyStatus,
    String? sortBy,
  }) async {
    final endpoint = _endpoint('/vocabulary', {
      'page': '$page',
      'limit': '$limit',
      if (level != null && level.isNotEmpty) 'level': level,
      if (studyStatus != null && studyStatus.isNotEmpty)
        'studyStatus': studyStatus,
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
    });

    return Paged.fromJson(await _apiClient.get(endpoint, cache: true), Vocabulary.fromJson);
  }

  /// Tìm từ vựng theo từ khoá. Không có kết quả là danh sách rỗng, không phải lỗi.
  Future<List<Vocabulary>> searchVocabularies({
    required String keyword,
    String? level,
  }) async {
    final endpoint = _endpoint('/vocabulary/search', {
      'keyword': keyword,
      if (level != null && level.isNotEmpty) 'level': level,
    });

    return listOf(await _apiClient.get(endpoint, cache: true), Vocabulary.fromJson);
  }

  Future<List<Vocabulary>> getVocabulariesByLesson(String lessonId) async {
    return listOf(await _apiClient.get('/vocabulary/lesson/$lessonId', cache: true), Vocabulary.fromJson);
  }

  /// Không đặt `cache`: chi tiết mang lịch ôn cá nhân, và đặt lại lịch bằng
  /// một bản lưu cũ sẽ gửi sai mốc hạn ôn kỳ vọng (spec SRS §4).
  Future<Vocabulary> getVocabularyById(String id) async {
    return objectOf(await _apiClient.get('/vocabulary/$id'), Vocabulary.fromJson);
  }

  /// Các bộ học của một cấp, kèm số từ đã học của người dùng.
  ///
  /// Không đặt `cache`: số từ đã học đổi sau mỗi lần học, bản lưu ngoại tuyến
  /// sẽ hiện tiến độ cũ.
  Future<List<VocabularySet>> getSets(String level) async {
    return listOf(await _apiClient.get(_endpoint('/vocabulary/sets', {'level': level})), VocabularySet.fromJson);
  }

  Future<VocabularySetDetail> getSet(String setId) async {
    return objectOf(
      await _apiClient.get('/vocabulary/sets/${Uri.encodeComponent(setId)}'),
      VocabularySetDetail.fromJson,
    );
  }

  /// Đánh dấu đã học: backend tạo tiến độ ôn tập ở box 1.
  Future<void> markAsLearned(String vocabularyId) => _apiClient.post('/vocabulary/$vocabularyId/mark-learned', {});

  Future<void> unmarkAsLearned(String vocabularyId) => _apiClient.delete('/vocabulary/$vocabularyId/mark-learned');

  String _endpoint(String path, Map<String, String> params) =>
      '$path?${Uri(queryParameters: params).query}';
}
