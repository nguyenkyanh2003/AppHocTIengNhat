import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_cache.dart';

class ApiClient {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _requestTimeout = Duration(seconds: 20);
  static const _uploadTimeout = Duration(seconds: 60);

  /// Chi tiết kỹ thuật (tên exception, địa chỉ máy chủ) chỉ ghi log, không lên giao diện.
  static const _unreachableMessage =
      'Không thể kết nối đến máy chủ. Kiểm tra mạng rồi thử lại.';

  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static const _secureStorage = FlutterSecureStorage();

  /// Route xác thực tự xử lý 401 của chính chúng (sai mật khẩu, refresh token
  /// hỏng): không bao giờ kích hoạt làm mới phiên.
  static const _authEndpoints = {
    '/users/login',
    '/users/refresh-token',
    '/users/logout'
  };

  final OfflineCache _cache = OfflineCache();

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static String get serverBaseUrl {
    final uri = Uri.parse(baseUrl);
    final segments = [...uri.pathSegments];
    if (segments.isNotEmpty && segments.last == 'api') segments.removeLast();
    return uri
        .replace(pathSegments: segments, query: null, fragment: null)
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  static String? resolveAssetUrl(String? value) {
    if (value == null || value.isEmpty) return value;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme == true) return value;
    return '$serverBaseUrl${value.startsWith('/') ? value : '/$value'}';
  }

  static String? _token;
  static String? _refreshToken;
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<void> init() async {
    _token = await _secureStorage.read(key: _tokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshKey);
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);
      if (legacyToken != null) {
        await setToken(legacyToken);
        await prefs.remove(_tokenKey);
      }
    }
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Lưu cặp token của phiên **mới** (vừa đăng nhập). Mọi request và phản hồi
  /// của phiên trước đó từ đây bị bỏ.
  Future<void> setSession(String accessToken, String? refreshToken) {
    _beginNewSession();
    return _storeTokens(accessToken, refreshToken);
  }

  Future<void> _storeTokens(String accessToken, String? refreshToken) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    if (refreshToken == null) {
      await _secureStorage.delete(key: _refreshKey);
    } else {
      await _secureStorage.write(key: _refreshKey, value: refreshToken);
    }
  }

  /// Xoá cả access token lẫn refresh token (đăng xuất, phiên kết thúc).
  ///
  /// Kho lưu chỉ bị xoá khi còn là của phiên này: trên web các tab dùng chung
  /// kho, và tab khác có thể đã đăng nhập một phiên khác vào đó.
  Future<void> removeToken() async {
    final ownToken = _token;
    _beginNewSession();
    _token = null;
    _refreshToken = null;

    final stored = await _secureStorage.read(key: _tokenKey);
    if (stored != null && !_isSameSession(stored, ownToken)) return;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshKey);
  }

  /// Nội dung của access token, `null` khi không đọc được. Chỉ dùng để so các
  /// token với nhau nên không cần kiểm chữ ký.
  static Map<dynamic, dynamic>? _claimsOf(String? accessToken) {
    final parts = accessToken?.split('.');
    if (parts == null || parts.length != 3) return null;
    try {
      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload is Map ? payload : null;
    } on FormatException {
      return null;
    }
  }

  /// Mã phiên `sid`: do server cấp và thuộc đúng một tài khoản, nên cùng `sid`
  /// cũng là cùng tài khoản.
  static String? _sessionIdOf(String accessToken) {
    final sid = _claimsOf(accessToken)?['sid'];
    return sid is String && sid.isNotEmpty ? sid : null;
  }

  /// Số lần phiên đã xoay refresh token khi cấp [accessToken]. Hai cặp token cùng
  /// phiên thì cặp có số lớn hơn là cặp mới hơn.
  static int _rotationOf(String? accessToken) {
    final rotation = _claimsOf(accessToken)?['rotation'];
    return rotation is int ? rotation : 0;
  }

  static bool _isSameSession(String? first, String? second) {
    if (first == null || second == null) return false;
    if (first == second) return true;
    final sessionId = _sessionIdOf(first);
    return sessionId != null && sessionId == _sessionIdOf(second);
  }

  /// Kho lưu giờ thuộc phiên khác (tab khác đã đăng xuất hoặc đăng nhập lại):
  /// tab này không được dùng cũng không được ghi đè kho đó. Huỷ yêu cầu đang
  /// chạy và báo phiên kết thúc để tab về màn đăng nhập; [removeToken] và
  /// [clearAllData] sẽ không đụng tới dữ liệu của phiên kia.
  Never _abandonToOtherTab() {
    _notifySessionExpired();
    throw SessionChangedException();
  }

  /// Báo [onSessionExpired], mỗi phiên một lần.
  void _notifySessionExpired() {
    if (_token == null || _expiredSessionNumber == _sessionNumber) return;
    _expiredSessionNumber = _sessionNumber;
    onSessionExpired?.call();
  }

  String? getToken() => _token;

  String? getRefreshToken() => _refreshToken;

  /// Số thứ tự phiên đăng nhập: tăng khi đăng nhập hoặc đăng xuất, giữ nguyên
  /// khi làm mới token. Request nào bắt đầu ở số cũ thì phản hồi của nó bị bỏ —
  /// không thì request của tài khoản A có thể bị gửi lại bằng token của B, trả
  /// dữ liệu của A cho màn hình của B, hay đăng xuất nhầm B.
  int _sessionNumber = 0;

  /// Phiên đã báo [onSessionExpired]: mỗi phiên chỉ báo một lần.
  int? _expiredSessionNumber;

  /// Lần làm mới đang chạy của phiên hiện tại; mọi request hết hạn cùng lúc chờ
  /// chung lần này. Phiên mới không chờ lần làm mới của phiên cũ.
  Future<bool>? _refreshing;

  void _beginNewSession() {
    _sessionNumber++;
    _refreshing = null;
  }

  void _requireSameSession(int sessionNumber) {
    if (sessionNumber != _sessionNumber) throw SessionChangedException();
  }

  /// Access token hết hạn (401 + [sessionExpiredCode]) trên một request có
  /// gửi token: đổi refresh token lấy cặp mới. `true` nghĩa là nên gửi lại
  /// request; `false` là phiên đã kết thúc thật.
  Future<bool> _renewedAfter(
      http.Response response, String endpoint, String? usedToken) async {
    if (response.statusCode != 401 ||
        usedToken == null ||
        _authEndpoints.contains(endpoint)) {
      return false;
    }
    if (_codeOf(response) != sessionExpiredCode) return false;
    // Request khác của phiên này đã làm mới trong lúc request này đang đi: chỉ
    // cần gửi lại. Đổi phiên thì caller đã chặn trước khi tới đây.
    if (_token != null && _token != usedToken) return true;
    return _sharedRefresh();
  }

  Future<bool> _sharedRefresh() {
    final running = _refreshing;
    if (running != null) return running;

    late final Future<bool> started;
    started = _refreshSession(_sessionNumber).whenComplete(() {
      if (identical(_refreshing, started)) _refreshing = null;
    });
    return _refreshing = started;
  }

  String? _codeOf(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data is Map ? data['code']?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  /// Gọi `POST /users/refresh-token`.
  ///
  /// `false` **chỉ** khi server xác nhận phiên đã kết thúc (401 kèm
  /// [sessionExpiredCode]). Mất mạng, máy chủ lỗi hay phản hồi hỏng đều là lỗi
  /// tạm thời: ném lỗi cho request đang chờ, giữ nguyên phiên để lần sau thử lại.
  Future<bool> _refreshSession(int sessionNumber) async {
    // Trên web các tab dùng chung kho lưu. Kho khác token đang giữ: nếu cùng
    // phiên thì tab kia vừa làm mới, dùng luôn cặp đó. Khác phiên thì tab kia đã
    // đổi tài khoản; gửi lại yêu cầu bằng token đó là ghi vào tài khoản khác.
    // Kho cũ hơn cặp đang giữ (hai tab ghi sát nhau) thì làm mới bằng cặp đang giữ.
    final stored = await _secureStorage.read(key: _refreshKey);
    _requireSameSession(sessionNumber);
    if (stored != null && stored != _refreshToken) {
      final storedAccess = await _secureStorage.read(key: _tokenKey);
      _requireSameSession(sessionNumber);
      if (!_isSameSession(storedAccess, _token)) _abandonToOtherTab();
      if (_rotationOf(storedAccess) >= _rotationOf(_token)) {
        _refreshToken = stored;
        _token = storedAccess;
        return true;
      }
    }

    final refreshToken = _refreshToken;
    if (refreshToken == null) return false;

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/users/refresh-token'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: json.encode({'refreshToken': refreshToken}),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw NetworkException('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (error) {
      debugPrint('Lỗi kết nối: $error');
      throw NetworkException(_unreachableMessage);
    }

    // Phản hồi về muộn sau khi đã đăng xuất hoặc đổi tài khoản: không được ghi
    // đè token của phiên hiện tại.
    _requireSameSession(sessionNumber);

    if (response.statusCode == 401 && _codeOf(response) == sessionExpiredCode) {
      return false;
    }

    final tokens = response.statusCode == 200 ? _tokensIn(response) : null;
    if (tokens == null) {
      throw ServerException(
        'Chưa làm mới được phiên đăng nhập. Vui lòng thử lại.',
        statusCode: response.statusCode,
        code: _codeOf(response),
      );
    }

    // Trong lúc chờ phản hồi, tab khác có thể đã đăng xuất hoặc đăng nhập phiên
    // khác: không ghi đè kho của họ, không làm token đã đăng xuất sống lại.
    final storedNow = await _secureStorage.read(key: _refreshKey);
    _requireSameSession(sessionNumber);
    if (storedNow != refreshToken) {
      final storedAccess = await _secureStorage.read(key: _tokenKey);
      _requireSameSession(sessionNumber);
      if (!_isSameSession(storedAccess, _token)) _abandonToOtherTab();
      // Hai tab cùng gửi một token thì server cấp lần lượt, còn phản hồi có thể về
      // ngược thứ tự. Cặp trong phản hồi này đã bị thay trên server: ghi vào kho
      // thì lần làm mới sau bị coi là dùng lại token cũ và mất cả phiên.
      if (_rotationOf(storedAccess) > _rotationOf(tokens.access)) {
        _refreshToken = storedNow;
        _token = storedAccess;
        return true;
      }
    }

    await _storeTokens(tokens.access, tokens.refresh);
    return true;
  }

  /// Cặp token trong phản hồi làm mới; `null` khi nội dung không đúng dạng.
  ({String access, String refresh})? _tokensIn(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is! Map) return null;
      final access = data['token'];
      final refresh = data['refreshToken'];
      if (access is! String ||
          access.isEmpty ||
          refresh is! String ||
          refresh.isEmpty) {
        return null;
      }
      return (access: access, refresh: refresh);
    } on FormatException {
      return null;
    }
  }

  /// Gọi khi backend báo token đang giữ không còn dùng được (mã
  /// [sessionExpiredCode]). `AuthProvider` đăng ký hàm này để tự dọn phiên và
  /// để router đưa người dùng về màn đăng nhập, thay vì mọi màn hình lần lượt
  /// hiện lỗi "phiên đăng nhập đã hết hạn".
  void Function()? onSessionExpired;

  static const sessionExpiredCode = 'SESSION_EXPIRED';

  final _writeListeners = <void Function(String method, String endpoint)>[];

  /// Nghe mọi lệnh ghi (POST/PUT/PATCH/DELETE) **thành công**, kèm phương thức
  /// và endpoint. Dành cho việc cần biết "vừa có thay đổi" mà không phải sửa
  /// từng service — hiện là báo huy hiệu vừa nhận (`AchievementAnnouncer`).
  void addWriteListener(void Function(String method, String endpoint) listener) =>
      _writeListeners.add(listener);

  void removeWriteListener(void Function(String method, String endpoint) listener) =>
      _writeListeners.remove(listener);

  /// Một người nghe hỏng không được làm lệnh ghi đã thành công trông như thất bại:
  /// lỗi được báo qua [FlutterError] thay vì ném về cho caller.
  void _notifyWrite(String method, String endpoint) {
    for (final listener in List.of(_writeListeners)) {
      try {
        listener(method, endpoint);
      } catch (error, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'api_client',
          context: ErrorDescription('khi báo lệnh ghi $method $endpoint'),
        ));
      }
    }
  }

  Future<Map<String, dynamic>> _write(
    String method,
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    final response = Map<String, dynamic>.from(
      await _jsonRequest(method, endpoint, body: body),
    );
    _notifyWrite(method, endpoint);
    return response;
  }

  /// Dọn dữ liệu cục bộ, gọi **sau** [removeToken]. Khi đó token còn trong kho
  /// là của phiên khác ở tab khác, nên dữ liệu dùng chung là của phiên đó: giữ nguyên.
  Future<void> clearAllData() async {
    if (await _secureStorage.read(key: _tokenKey) != null) return;

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) =>
        key.startsWith('user_data_') ||
        key.startsWith('cached_') ||
        key == 'current_user_id' ||
        key == OfflineCache.storageKey);
    await Future.wait(keys.map(prefs.remove));
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Gọi GET. Đặt [cache] khi endpoint trả về nội dung học tĩnh: kết quả được
  /// lưu lại và dùng làm dự phòng nếu người dùng bật chế độ ngoại tuyến và
  /// request thất bại.
  Future<dynamic> get(String endpoint, {bool cache = false}) async {
    try {
      final response = await _jsonRequest('GET', endpoint);
      if (cache) await _cache.write(endpoint, response);
      return response;
    } on SessionChangedException {
      rethrow;
    } catch (_) {
      if (!cache || !await _cache.isEnabled()) rethrow;
      final cached = await _cache.read(endpoint);
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<void> setOfflineModeEnabled(bool enabled) =>
      _cache.setEnabled(enabled);

  Future<bool> isOfflineModeEnabled() => _cache.isEnabled();

  Future<Map<String, dynamic>> offlineCacheInfo() => _cache.info();

  Future<void> clearOfflineCache() => _cache.clear();

  Future<int> preloadOfflineContent({
    bool lessons = true,
    bool vocabulary = true,
    bool kanji = true,
    bool grammar = true,
  }) async {
    final endpoints = <String>[
      if (lessons) '/lesson?limit=100',
      if (vocabulary) '/vocabulary?limit=100',
      if (kanji) '/kanji?limit=100',
      if (grammar) '/grammar?limit=100',
    ];
    var loaded = 0;
    for (final endpoint in endpoints) {
      await get(endpoint, cache: true);
      loaded++;
    }
    return loaded;
  }

  Future<int> syncOfflineCache() async {
    var synced = 0;
    for (final endpoint in await _cache.keys()) {
      try {
        await _cache.write(endpoint, await _jsonRequest('GET', endpoint));
        synced++;
      } catch (_) {
        // Giữ giá trị cũ nếu một endpoint không làm mới được.
      }
    }
    return synced;
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) =>
      _write('POST', endpoint, data);

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) =>
      _write('PUT', endpoint, data);

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) =>
      _write('PATCH', endpoint, data);

  Future<Map<String, dynamic>> delete(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) =>
      _write('DELETE', endpoint, body);

  Future<dynamic> _jsonRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final sessionNumber = _sessionNumber;
    final usedToken = _token;
    final response = await _sendJson(method, endpoint, body);
    _requireSameSession(sessionNumber);
    // Access token hết hạn: làm mới phiên rồi gửi lại **một** lần.
    if (await _renewedAfter(response, endpoint, usedToken)) {
      _requireSameSession(sessionNumber);
      final retried = await _sendJson(method, endpoint, body);
      _requireSameSession(sessionNumber);
      return _handleResponse(retried);
    }
    _requireSameSession(sessionNumber);
    return _handleResponse(response);
  }

  Future<http.Response> _sendJson(
    String method,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final encodedBody = body == null ? null : json.encode(body);
      return switch (method) {
        'GET' =>
          await http.get(url, headers: _headers).timeout(_requestTimeout),
        'POST' => await http
            .post(url, headers: _headers, body: encodedBody)
            .timeout(_requestTimeout),
        'PUT' => await http
            .put(url, headers: _headers, body: encodedBody)
            .timeout(_requestTimeout),
        'PATCH' => await http
            .patch(url, headers: _headers, body: encodedBody)
            .timeout(_requestTimeout),
        'DELETE' => await http
            .delete(url, headers: _headers, body: encodedBody)
            .timeout(_requestTimeout),
        _ => throw ArgumentError('HTTP method không được hỗ trợ: $method'),
      };
    } on ArgumentError {
      rethrow;
    } on TimeoutException {
      throw NetworkException('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (error) {
      debugPrint('Lỗi kết nối: $error');
      throw NetworkException(_unreachableMessage);
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    List<int> fileBytes,
    String fileName,
  ) =>
      _multipartRequest(
        'POST',
        endpoint,
        fields,
        fileFieldName,
        fileBytes,
        fileName,
      );

  Future<Map<String, dynamic>> putMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    List<int> fileBytes,
    String fileName,
  ) =>
      _multipartRequest(
        'PUT',
        endpoint,
        fields,
        fileFieldName,
        fileBytes,
        fileName,
      );

  Future<Map<String, dynamic>> _multipartRequest(
    String method,
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    List<int> fileBytes,
    String fileName,
  ) async {
    // Dựng lại request mỗi lần gửi: một MultipartRequest chỉ gửi được một lần.
    Future<http.Response> send() => _sendMultipart(
        method, endpoint, fields, fileFieldName, fileBytes, fileName);

    final sessionNumber = _sessionNumber;
    final usedToken = _token;
    var response = await send();
    _requireSameSession(sessionNumber);
    if (await _renewedAfter(response, endpoint, usedToken)) {
      _requireSameSession(sessionNumber);
      response = await send();
    }
    _requireSameSession(sessionNumber);
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<http.Response> _sendMultipart(
    String method,
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final request =
          http.MultipartRequest(method, Uri.parse('$baseUrl$endpoint'));
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
      request.fields.addAll(fields);
      request.files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileName,
        contentType: _mediaTypeFor(fileName),
      ));
      final streamed = await request.send().timeout(_uploadTimeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw NetworkException('Tải tệp quá thời gian. Vui lòng thử lại.');
    } catch (error) {
      debugPrint('Lỗi tải tệp: $error');
      throw NetworkException(
          'Không thể tải tệp lên. Kiểm tra mạng rồi thử lại.');
    }
  }

  MediaType? _mediaTypeFor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const types = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'm4a': 'audio/mp4',
      'ogg': 'audio/ogg',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    final value = types[extension];
    return value == null ? null : MediaType.parse(value);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = response.body.isEmpty
          ? <String, dynamic>{}
          : json.decode(response.body);
    } on FormatException {
      throw ServerException('Máy chủ trả về dữ liệu không hợp lệ.');
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) return data;
    final body =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final message = body['message']?.toString();
    final code = body['code']?.toString();
    final details = body['details'] is Map<String, dynamic>
        ? body['details'] as Map<String, dynamic>
        : null;

    if (code == sessionExpiredCode) _notifySessionExpired();

    if (status == 401 || status == 403) {
      throw UnauthorizedException(message ?? 'Phiên đăng nhập không hợp lệ.',
          statusCode: status, code: code, details: details);
    }
    if (status == 404) {
      throw NotFoundException(message ?? 'Không tìm thấy dữ liệu.',
          statusCode: status, code: code, details: details);
    }
    if (status >= 400 && status < 500) {
      throw BadRequestException(message ?? 'Yêu cầu không hợp lệ.',
          statusCode: status, code: code, details: details);
    }
    throw ServerException(message ?? 'Máy chủ đang gặp sự cố.',
        statusCode: status, code: code, details: details);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Mã nghiệp vụ backend gửi kèm, ví dụ `SESSION_EXPIRED`.
  final String? code;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.statusCode, this.code, this.details});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message,
      {super.statusCode, super.code, super.details});
}

class NotFoundException extends ApiException {
  NotFoundException(super.message,
      {super.statusCode, super.code, super.details});
}

class BadRequestException extends ApiException {
  BadRequestException(super.message,
      {super.statusCode, super.code, super.details});
}

class ServerException extends ApiException {
  ServerException(super.message, {super.statusCode, super.code, super.details});
}

class NetworkException extends ApiException {
  NetworkException(super.message,
      {super.statusCode, super.code, super.details});
}

/// Phản hồi thuộc phiên đăng nhập đã kết thúc (đã đăng xuất hoặc đổi tài khoản
/// trong lúc request đang đi) nên bị bỏ. Không phải lỗi của server.
class SessionChangedException extends ApiException {
  SessionChangedException() : super('Phiên đăng nhập đã thay đổi.');
}
