import '../network/api_client.dart';

class AppConstants {
  static String get baseUrl => ApiClient.baseUrl;

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const String loginEndpoint = '/users/login';
  static const String registerEndpoint = '/users/register';
  static const String vocabularyEndpoint = '/vocabulary';
  static const String grammarEndpoint = '/grammar';
  static const String kanjiEndpoint = '/kanji';
  static const String lessonEndpoint = '/lesson';
  static const String exerciseEndpoint = '/exercise';
  static const String jlptEndpoint = '/jlpt';
  static const String notebookEndpoint = '/notebook';
  static const String newsEndpoint = '/news';
  static const String groupEndpoint = '/group';
  static const String notificationEndpoint = '/notifications';

  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  static const int pageSize = 20;

  static const List<String> jlptLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];
}
