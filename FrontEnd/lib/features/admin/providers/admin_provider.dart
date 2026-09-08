import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  /// Nhận service qua constructor để test truyền bản giả.
  AdminProvider({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  final AdminService _adminService;

  // Dashboard Stats
  Map<String, dynamic>? _dashboardStats;
  bool _isLoadingStats = false;

  // Users
  List<dynamic> _users = [];
  bool _isLoadingUsers = false;
  Map<String, dynamic>? _userStats;

  // Content
  List<dynamic> _vocabulary = [];
  List<dynamic> _kanji = [];
  List<dynamic> _grammar = [];
  List<dynamic> _lessons = [];
  bool _isLoadingContent = false;

  // Reports
  List<dynamic> _reports = [];
  bool _isLoadingReports = false;
  Map<String, dynamic>? _reportStats;

  // Achievements
  List<dynamic> _achievements = [];
  bool _isLoadingAchievements = false;

  // Transactions
  List<dynamic> _transactions = [];
  bool _isLoadingTransactions = false;

  // Analytics
  Map<String, dynamic>? _analytics;
  bool _isLoadingAnalytics = false;

  // Error
  String? _error;

  // General loading state
  bool get isLoading =>
      _isLoadingStats ||
      _isLoadingUsers ||
      _isLoadingContent ||
      _isLoadingReports ||
      _isLoadingAchievements ||
      _isLoadingTransactions ||
      _isLoadingAnalytics;

  // Getters
  Map<String, dynamic> get dashboardStats => _dashboardStats ?? {};
  bool get isLoadingStats => _isLoadingStats;

  List<Map<String, dynamic>> get users =>
      _users.map((e) => Map<String, dynamic>.from(e)).toList();
  bool get isLoadingUsers => _isLoadingUsers;
  Map<String, dynamic>? get userStats => _userStats;

  List<Map<String, dynamic>> get vocabulary =>
      _vocabulary.map((e) => Map<String, dynamic>.from(e)).toList();
  List<Map<String, dynamic>> get kanji =>
      _kanji.map((e) => Map<String, dynamic>.from(e)).toList();
  List<Map<String, dynamic>> get grammar =>
      _grammar.map((e) => Map<String, dynamic>.from(e)).toList();
  List<Map<String, dynamic>> get lessons =>
      _lessons.map((e) => Map<String, dynamic>.from(e)).toList();
  bool get isLoadingContent => _isLoadingContent;

  List<Map<String, dynamic>> get reports =>
      _reports.map((e) => Map<String, dynamic>.from(e)).toList();
  bool get isLoadingReports => _isLoadingReports;
  Map<String, dynamic>? get reportStats => _reportStats;

  List<Map<String, dynamic>> get achievements =>
      _achievements.map((e) => Map<String, dynamic>.from(e)).toList();
  bool get isLoadingAchievements => _isLoadingAchievements;

  List<Map<String, dynamic>> get transactions =>
      _transactions.map((e) => Map<String, dynamic>.from(e)).toList();
  bool get isLoadingTransactions => _isLoadingTransactions;

  Map<String, dynamic>? get analytics => _analytics;
  bool get isLoadingAnalytics => _isLoadingAnalytics;

  String? get error => _error;

  // ==================== DASHBOARD ====================

  Future<void> loadDashboardStats() async {
    _isLoadingStats = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardStats = await _adminService.getDashboardStats();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading dashboard stats: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // ==================== USERS ====================

  Future<void> loadUsers({String? search, String? status, String? role}) async {
    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminService.getAllUsers(
        search: search,
        status: status,
        role: role,
      );
      _userStats = await _adminService.getUserStats();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading users: $e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> banUser(String userId) async {
    try {
      await _adminService.banUser(userId);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unbanUser(String userId) async {
    try {
      await _adminService.unbanUser(userId);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> promoteToAdmin(String userId) async {
    try {
      await _adminService.promoteToAdmin(userId);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> demoteToUser(String userId) async {
    try {
      await _adminService.demoteToUser(userId);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== CONTENT ====================

  Future<void> loadVocabulary({String? level}) async {
    _isLoadingContent = true;
    notifyListeners();

    try {
      _vocabulary = await _adminService.getVocabulary(level: level);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingContent = false;
      notifyListeners();
    }
  }

  Future<bool> createVocabulary(Map<String, dynamic> data) async {
    try {
      await _adminService.createVocabulary(data);
      await loadVocabulary();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVocabulary(String id, Map<String, dynamic> data) async {
    try {
      await _adminService.updateVocabulary(id, data);
      await loadVocabulary();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVocabulary(String id) async {
    try {
      await _adminService.deleteVocabulary(id);
      await loadVocabulary();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadKanji({String? level}) async {
    _isLoadingContent = true;
    notifyListeners();

    try {
      _kanji = await _adminService.getKanji(level: level);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingContent = false;
      notifyListeners();
    }
  }

  Future<bool> createKanji(Map<String, dynamic> data) async {
    try {
      await _adminService.createKanji(data);
      await loadKanji();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateKanji(String id, Map<String, dynamic> data) async {
    try {
      await _adminService.updateKanji(id, data);
      await loadKanji();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKanji(String id) async {
    try {
      await _adminService.deleteKanji(id);
      await loadKanji();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadGrammar({String? level}) async {
    _isLoadingContent = true;
    notifyListeners();

    try {
      _grammar = await _adminService.getGrammar(level: level);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingContent = false;
      notifyListeners();
    }
  }

  Future<bool> createGrammar(Map<String, dynamic> data) async {
    try {
      await _adminService.createGrammar(data);
      await loadGrammar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGrammar(String id, Map<String, dynamic> data) async {
    try {
      await _adminService.updateGrammar(id, data);
      await loadGrammar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGrammar(String id) async {
    try {
      await _adminService.deleteGrammar(id);
      await loadGrammar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadLessons({String? level}) async {
    _isLoadingContent = true;
    notifyListeners();

    try {
      _lessons = await _adminService.getLessons(level: level);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingContent = false;
      notifyListeners();
    }
  }

  Future<bool> createLesson(Map<String, dynamic> data) async {
    try {
      await _adminService.createLesson(data);
      await loadLessons();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLesson(String id, Map<String, dynamic> data) async {
    try {
      await _adminService.updateLesson(id, data);
      await loadLessons();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLesson(String id) async {
    try {
      await _adminService.deleteLesson(id);
      await loadLessons();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> importContent(
    String contentType,
    List<Map<String, dynamic>> rows,
  ) async {
    _isLoadingContent = true;
    _error = null;
    notifyListeners();
    var imported = 0;

    try {
      for (var index = 0; index < rows.length; index++) {
        try {
          switch (contentType) {
            case 'vocabulary':
              await _adminService.createVocabulary(rows[index]);
              break;
            case 'kanji':
              await _adminService.createKanji(rows[index]);
              break;
            case 'grammar':
              await _adminService.createGrammar(rows[index]);
              break;
            case 'lessons':
              await _adminService.createLesson(rows[index]);
              break;
            default:
              throw ArgumentError('Loại nội dung không được hỗ trợ.');
          }
          imported++;
        } catch (e) {
          throw Exception('Dòng dữ liệu ${index + 2}: $e');
        }
      }
      return imported;
    } catch (e) {
      _error = e.toString();
      return imported;
    } finally {
      _isLoadingContent = false;
      await _reloadContent(contentType);
    }
  }

  /// Import nội dung từ tệp Excel.
  ///
  /// `lesson` và `level` chỉ dùng cho từ vựng: backend áp hai giá trị này cho
  /// mọi dòng của tệp. Kanji đọc bài học và cấp độ theo từng dòng nên không
  /// nhận metadata dùng chung.
  Future<bool> importExcel(
    String contentType,
    List<int> bytes,
    String fileName, {
    String? lesson,
    String? level,
  }) async {
    _isLoadingContent = true;
    _error = null;
    notifyListeners();
    try {
      switch (contentType) {
        case 'vocabulary':
          if (lesson == null || lesson.isEmpty || level == null || level.isEmpty) {
            throw ArgumentError('Cần chọn bài học và cấp độ trước khi import.');
          }
          await _adminService.importVocabularyExcel(
            bytes,
            fileName,
            lesson: lesson,
            level: level,
          );
          break;
        case 'kanji':
          await _adminService.importKanjiExcel(bytes, fileName);
          break;
        default:
          throw ArgumentError('Excel chỉ hỗ trợ từ vựng và Kanji.');
      }
      await _reloadContent(contentType);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoadingContent = false;
      notifyListeners();
    }
  }

  Future<void> _reloadContent(String contentType) async {
    switch (contentType) {
      case 'vocabulary':
        await loadVocabulary();
        break;
      case 'kanji':
        await loadKanji();
        break;
      case 'grammar':
        await loadGrammar();
        break;
      case 'lessons':
        await loadLessons();
        break;
    }
  }

  // ==================== REPORTS ====================

  Future<void> loadReports({String? status, String? type}) async {
    _isLoadingReports = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _adminService.getReports(status: status, type: type);
      _reportStats = await _adminService.getReportStats();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading reports: $e');
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  Future<bool> respondToReport(
      String reportId, String response, String status) async {
    try {
      await _adminService.respondToReport(reportId, response, status);
      await loadReports();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      await _adminService.deleteReport(reportId);
      await loadReports();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== ACHIEVEMENTS ====================

  Future<void> loadAchievements() async {
    _isLoadingAchievements = true;
    _error = null;
    notifyListeners();

    try {
      _achievements = await _adminService.getAchievements();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading achievements: $e');
    } finally {
      _isLoadingAchievements = false;
      notifyListeners();
    }
  }

  Future<bool> createAchievement(Map<String, dynamic> data) async {
    try {
      await _adminService.createAchievement(data);
      await loadAchievements();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAchievement(String id, Map<String, dynamic> data) async {
    try {
      await _adminService.updateAchievement(id, data);
      await loadAchievements();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAchievement(String id) async {
    try {
      await _adminService.deleteAchievement(id);
      await loadAchievements();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<void> loadTransactions({String? status}) async {
    _isLoadingTransactions = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _adminService.getTransactions(status: status);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  Future<bool> updateTransactionStatus(String id, String status) async {
    try {
      await _adminService.updateTransactionStatus(id, status);
      await loadTransactions();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== ANALYTICS ====================

  Future<void> loadAnalytics({String period = '7d'}) async {
    _isLoadingAnalytics = true;
    _error = null;
    notifyListeners();

    try {
      _analytics = await _adminService.getAnalytics(period: period);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading analytics: $e');
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  // ==================== NOTIFICATIONS ====================

  Future<bool> sendNotificationToUser(
      String userId, String title, String body) async {
    try {
      await _adminService.sendNotification(userId, {
        'title': title,
        'body': body,
        'type': 'admin_message',
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> broadcastNotification(String title, String body) async {
    try {
      await _adminService.broadcastNotification({
        'title': title,
        'body': body,
        'type': 'broadcast',
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
