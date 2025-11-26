class AppConstants {
  // API Base URL - Đổi theo môi trường
  static const String baseUrl = 'http://localhost:3000/api';
  
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  static const String loginEndpoint = '/api/users';
  static const String registerEndpoint = '/api/users';
  static const String vocabularyEndpoint = '/vocabulary';
  static const String grammarEndpoint = '/grammar';
  static const String kanjiEndpoint = '/kanji';
  static const String lessonEndpoint = '/lesson';
  static const String exerciseEndpoint = '/exercise';
  static const String jlptEndpoint = '/jlpt';
  static const String notebookEndpoint = '/notebook';
  static const String newsEndpoint = '/news';
  static const String groupEndpoint = '/group';
  static const String notificationEndpoint = '/notification';

  static const int connectionTimeout = 30; 
  static const int receiveTimeout = 30; 
  
 
  static const int pageSize = 20;
  
  static const List<String> jlptLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];
}