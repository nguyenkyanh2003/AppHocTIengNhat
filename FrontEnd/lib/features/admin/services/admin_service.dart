import '../../../core/network/api_client.dart';

class AdminService {
  /// Nhận client qua constructor để test truyền transport giả.
  AdminService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  String _query(Map<String, Object?> values) {
    final parameters = <String, String>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value != null && value.toString().isNotEmpty) {
        parameters[entry.key] = value.toString();
      }
    }
    return parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
  }

  List<dynamic> _list(dynamic response, List<String> keys) {
    if (response is List) return response;
    if (response is Map) {
      for (final key in keys) {
        final value = response[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic> _map(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return const {};
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final results = await Future.wait([
      _client.get('/users/admin/stats'),
      _client.get('/lesson/stats/overview'),
      _client.get('/report/admin/stats'),
    ]);
    return {
      'users': _map(results[0]),
      'lessons': _map(results[1]),
      'reports': _map(results[2]),
    };
  }

  Future<List<dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? role,
  }) async {
    final query = _query({
      'page': page,
      'limit': limit,
      'search': search,
      'status': status,
      'role': role,
    });
    final response = await _client.get('/users/admin/users$query');
    return _list(response, const ['data', 'users']).map((item) {
      final user = Map<String, dynamic>.from(item as Map);
      return {
        ...user,
        'id': (user['_id'] ?? user['id'])?.toString(),
        'name': user['HoTen'] ?? user['name'] ?? user['TenDangNhap'] ?? '',
        'email': user['Email'] ?? user['email'] ?? '',
        'role': user['VaiTro'] ?? user['role'] ?? 'user',
        'status': user['TrangThai'] ?? user['status'] ?? 'active',
        'level': user['TrinhDo'] ?? user['level'] ?? 'N5',
        'joinDate': user['NgayTao'] ?? user['createdAt'] ?? '',
        'lastActive': user['LanDangNhapCuoi'] ?? 'Chưa có',
        'totalXP': user['DiemTichLuy'] ?? 0,
        'streak': user['StreakHienTai'] ?? 0,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> getUserStats() async =>
      _map(await _client.get('/users/admin/stats'));

  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) =>
      _client.put('/users/admin/users/$userId', data);

  Future<void> deleteUser(String userId) async {
    await _client.delete('/users/admin/users/$userId');
  }

  Future<Map<String, dynamic>> banUser(String userId) =>
      updateUser(userId, {'trangThai': 'banned'});

  Future<Map<String, dynamic>> unbanUser(String userId) =>
      updateUser(userId, {'trangThai': 'active'});

  Future<Map<String, dynamic>> promoteToAdmin(String userId) =>
      updateUser(userId, {'vaiTro': 'admin'});

  Future<Map<String, dynamic>> demoteToUser(String userId) =>
      updateUser(userId, {'vaiTro': 'user'});

  Future<List<dynamic>> getVocabulary({
    int page = 1,
    int limit = 50,
    String? level,
  }) async {
    final response = await _client.get(
      '/vocabulary${_query({'page': page, 'limit': limit, 'level': level})}',
    );
    return _list(response, const ['data', 'vocabularies']);
  }

  Future<Map<String, dynamic>> createVocabulary(Map<String, dynamic> data) =>
      _client.post('/vocabulary', data);

  Future<Map<String, dynamic>> updateVocabulary(
    String id,
    Map<String, dynamic> data,
  ) =>
      _client.put('/vocabulary/$id', data);

  Future<void> deleteVocabulary(String id) async {
    await _client.delete('/vocabulary/$id');
  }

  /// Import từ vựng từ Excel.
  ///
  /// Backend bắt buộc `lesson` và `level` trong multipart và áp cho **mọi** dòng
  /// của tệp; thiếu một trong hai thì toàn bộ request bị từ chối với lỗi 400.
  Future<Map<String, dynamic>> importVocabularyExcel(
    List<int> bytes,
    String fileName, {
    required String lesson,
    required String level,
  }) =>
      _client.postMultipart(
        '/vocabulary/upload',
        {'lesson': lesson, 'level': level},
        'fileExcel',
        bytes,
        fileName,
      );

  Future<List<dynamic>> getKanji({
    int page = 1,
    int limit = 50,
    String? level,
  }) async {
    final response = await _client.get(
      '/kanji${_query({'page': page, 'limit': limit, 'level': level})}',
    );
    return _list(response, const ['data', 'kanjis']);
  }

  Future<Map<String, dynamic>> createKanji(Map<String, dynamic> data) =>
      _client.post('/kanji', data);

  Future<Map<String, dynamic>> updateKanji(
    String id,
    Map<String, dynamic> data,
  ) =>
      _client.put('/kanji/$id', data);

  Future<void> deleteKanji(String id) async {
    await _client.delete('/kanji/$id');
  }

  /// Import Kanji từ Excel.
  ///
  /// Khác với từ vựng: importer của Kanji đọc `BaiHocID` và `CapDo` từ **từng
  /// dòng** Excel, nên không gửi kèm metadata dùng chung cho cả tệp.
  Future<Map<String, dynamic>> importKanjiExcel(
    List<int> bytes,
    String fileName,
  ) =>
      _client.postMultipart(
        '/kanji/upload',
        const {},
        'fileExcel',
        bytes,
        fileName,
      );

  Future<List<dynamic>> getGrammar({
    int page = 1,
    int limit = 50,
    String? level,
  }) async {
    final response = await _client.get(
      '/grammar${_query({'page': page, 'limit': limit, 'level': level})}',
    );
    return _list(response, const ['data', 'grammars']);
  }

  Future<Map<String, dynamic>> createGrammar(Map<String, dynamic> data) =>
      _client.post('/grammar', data);

  Future<Map<String, dynamic>> updateGrammar(
    String id,
    Map<String, dynamic> data,
  ) =>
      _client.put('/grammar/$id', data);

  Future<void> deleteGrammar(String id) async {
    await _client.delete('/grammar/$id');
  }

  Future<List<dynamic>> getLessons({
    int page = 1,
    int limit = 50,
    String? level,
  }) async {
    final response = await _client.get(
      '/lesson${_query({'page': page, 'limit': limit, 'level': level})}',
    );
    return _list(response, const ['data', 'lessons']);
  }

  Future<Map<String, dynamic>> createLesson(Map<String, dynamic> data) =>
      _client.post('/lesson', data);

  Future<Map<String, dynamic>> updateLesson(
    String id,
    Map<String, dynamic> data,
  ) =>
      _client.put('/lesson/$id', data);

  Future<void> deleteLesson(String id) async {
    await _client.delete('/lesson/$id');
  }

  Future<List<dynamic>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    final query = _query({
      'page': page,
      'limit': limit,
      'status': status,
      'type': type,
    });
    final response = await _client.get('/report/admin/all$query');
    final reports = _list(response, const ['data', 'reports']);
    return reports.map((item) {
      final report = Map<String, dynamic>.from(item as Map);
      final user = report['user_id'];
      if (user is Map) {
        report['user'] = user['HoTen'] ?? user['TenDangNhap'] ?? user['Email'];
      }
      return report;
    }).toList();
  }

  Future<Map<String, dynamic>> getReportStats() async =>
      _map(await _client.get('/report/admin/stats'));

  Future<Map<String, dynamic>> respondToReport(
    String reportId,
    String response,
    String status,
  ) =>
      _client.put('/report/admin/$reportId/status', {
        'admin_response': response,
        'status': status,
      });

  Future<void> deleteReport(String reportId) async {
    await _client.delete('/report/admin/$reportId');
  }

  Future<List<dynamic>> getAchievements() async {
    final response = await _client.get('/achievement/admin/all');
    return _list(response, const ['data', 'achievements']).map((item) {
      final achievement = Map<String, dynamic>.from(item as Map);
      achievement['xp'] = achievement['xp_reward'] ?? 0;
      achievement['condition'] = achievement['requirement_value'] ?? 0;
      achievement['unlocked'] = achievement['unlocked'] ?? 0;
      return achievement;
    }).toList();
  }

  Map<String, dynamic> _achievementPayload(Map<String, dynamic> data) {
    final name = data['name']?.toString().trim() ?? '';
    final description = data['description']?.toString().trim() ?? '';
    return {
      'name': name,
      'name_vi': data['name_vi'] ?? name,
      'description': description,
      'description_vi': data['description_vi'] ?? description,
      'icon': data['icon']?.toString().trim().isNotEmpty == true
          ? data['icon']
          : '🏆',
      'category': data['category'] ?? 'practice',
      'requirement_type': data['requirement_type'] ?? 'count',
      'requirement_value': data['requirement_value'] ??
          int.tryParse(data['condition']?.toString() ?? '') ??
          1,
      'xp_reward': data['xp_reward'] ?? data['xp'] ?? 100,
      'rarity': data['rarity'] ?? 'common',
      if (data.containsKey('is_active')) 'is_active': data['is_active'],
    };
  }

  Future<Map<String, dynamic>> createAchievement(
    Map<String, dynamic> data,
  ) =>
      _client.post('/achievement/admin', _achievementPayload(data));

  Future<Map<String, dynamic>> updateAchievement(
    String id,
    Map<String, dynamic> data,
  ) =>
      _client.put('/achievement/admin/$id', _achievementPayload(data));

  Future<void> deleteAchievement(String id) async {
    await _client.delete('/achievement/admin/$id');
  }

  Future<List<dynamic>> getTransactions({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final query = _query({
      'page': page,
      'limit': limit,
      'status': status,
    });
    final response = await _client.get('/transactions/admin/all$query');
    return _list(response, const ['data', 'transactions']);
  }

  Future<Map<String, dynamic>> updateTransactionStatus(
    String id,
    String status,
  ) =>
      _client.put('/transactions/admin/$id/status', {'status': status});

  Future<Map<String, dynamic>> sendNotification(
    String userId,
    Map<String, dynamic> data,
  ) =>
      _client.post('/notifications', {'userId': userId, ...data});

  Future<Map<String, dynamic>> broadcastNotification(
    Map<String, dynamic> data,
  ) =>
      _client.post('/notifications/broadcast/all', data);

  Future<Map<String, dynamic>> getAnalytics({String period = '7d'}) async =>
      _map(
        await _client.get(
          '/progress/admin/analytics${_query({'period': period})}',
        ),
      );
}
