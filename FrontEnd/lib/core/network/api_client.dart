import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _requestTimeout = Duration(seconds: 20);
  static const _uploadTimeout = Duration(seconds: 60);
  static const _tokenKey = 'auth_token';
  static const _offlineModeKey = 'offline_mode_enabled';
  static const _contentCacheKey = 'offline_content_cache_v1';
  static const _secureStorage = FlutterSecureStorage();

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
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<void> init() async {
    _token = await _secureStorage.read(key: _tokenKey);
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

  Future<void> removeToken() async {
    _token = null;
    await _secureStorage.delete(key: _tokenKey);
  }

  String? getToken() => _token;

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) =>
        key.startsWith('user_data_') ||
        key.startsWith('cached_') ||
        key == 'current_user_id' ||
        key == _contentCacheKey);
    await Future.wait(keys.map(prefs.remove));
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _jsonRequest('GET', endpoint);
      if (_isCacheable(endpoint)) await _cacheResponse(endpoint, response);
      return response;
    } catch (_) {
      if (!await isOfflineModeEnabled() || !_isCacheable(endpoint)) rethrow;
      final cached = await _cachedResponse(endpoint);
      if (cached == null) rethrow;
      return cached;
    }
  }

  bool _isCacheable(String endpoint) {
    const roots = [
      '/lesson',
      '/vocabulary',
      '/kanji',
      '/grammar',
      '/exercise',
      '/news',
    ];
    return roots.any(
      (root) =>
          endpoint == root ||
          endpoint.startsWith('$root?') ||
          endpoint.startsWith('$root/'),
    );
  }

  Future<void> setOfflineModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, enabled);
  }

  Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }

  Future<Map<String, dynamic>> offlineCacheInfo() async {
    final cache = await _readCache();
    final encoded = jsonEncode(cache);
    DateTime? latest;
    for (final entry in cache.values) {
      if (entry is! Map || entry['cachedAt'] is! String) continue;
      final date = DateTime.tryParse(entry['cachedAt'] as String);
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return {
      'items': cache.length,
      'bytes': utf8.encode(encoded).length,
      'lastSync': latest,
    };
  }

  Future<void> clearOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contentCacheKey);
  }

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
      await get(endpoint);
      loaded++;
    }
    return loaded;
  }

  Future<int> syncOfflineCache() async {
    final cache = await _readCache();
    var synced = 0;
    for (final endpoint in cache.keys.toList()) {
      try {
        final response = await _jsonRequest('GET', endpoint);
        await _cacheResponse(endpoint, response);
        synced++;
      } catch (_) {
        // Keep the previous cached value if one endpoint cannot be refreshed.
      }
    }
    return synced;
  }

  Future<Map<String, dynamic>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_contentCacheKey);
    if (encoded == null || encoded.isEmpty) return {};
    try {
      final decoded = jsonDecode(encoded);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      await prefs.remove(_contentCacheKey);
      return {};
    }
  }

  Future<void> _cacheResponse(String endpoint, dynamic response) async {
    final cache = await _readCache();
    cache[endpoint] = {
      'cachedAt': DateTime.now().toIso8601String(),
      'data': response,
    };
    if (cache.length > 50) cache.remove(cache.keys.first);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contentCacheKey, jsonEncode(cache));
  }

  Future<dynamic> _cachedResponse(String endpoint) async {
    final cache = await _readCache();
    final entry = cache[endpoint];
    return entry is Map ? entry['data'] : null;
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async =>
      Map<String, dynamic>.from(
        await _jsonRequest('POST', endpoint, body: data),
      );

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async =>
      Map<String, dynamic>.from(
        await _jsonRequest('PUT', endpoint, body: data),
      );

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async =>
      Map<String, dynamic>.from(
        await _jsonRequest('PATCH', endpoint, body: data),
      );

  Future<Map<String, dynamic>> delete(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async =>
      Map<String, dynamic>.from(
        await _jsonRequest('DELETE', endpoint, body: body),
      );

  Future<dynamic> _jsonRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final encodedBody = body == null ? null : json.encode(body);
      final response = switch (method) {
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
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw NetworkException('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } catch (error) {
      throw NetworkException('Không thể kết nối đến máy chủ: $error');
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
      final response = await http.Response.fromStream(streamed);
      return Map<String, dynamic>.from(_handleResponse(response));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw NetworkException('Tải tệp quá thời gian. Vui lòng thử lại.');
    } catch (error) {
      throw NetworkException('Không thể tải tệp: $error');
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

    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    final message =
        data is Map<String, dynamic> ? data['message']?.toString() : null;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw UnauthorizedException(message ?? 'Phiên đăng nhập không hợp lệ.');
    }
    if (response.statusCode == 404) {
      throw NotFoundException(message ?? 'Không tìm thấy dữ liệu.');
    }
    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw BadRequestException(message ?? 'Yêu cầu không hợp lệ.');
    }
    throw ServerException(message ?? 'Máy chủ đang gặp sự cố.');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}
