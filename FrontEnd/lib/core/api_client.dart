import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

class ApiClient {
  // Sử dụng localhost cho web, 10.0.2.2 cho Android emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      return 'http://10.0.2.2:3000/api';
    }
  }
  
  static String? _token;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
// Remove Token
  Future<void> removeToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  String? getToken() => _token;

  /// Clear all cached data (for logout)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    // Remove all data except settings
    final keys = prefs.getKeys().where((key) => 
      key.startsWith('user_data_') || 
      key.startsWith('cached_') ||
      key == 'current_user_id'
    ).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
// GET Request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('GET: $url');
      
      final response = await http.get(url, headers: _headers);
      
      return _handleResponse(response);
    } catch (e) {
      print('GET Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
// POST Request
  Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('POST: $url');
      print('Data: ${json.encode(data)}');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('POST Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // PUT Request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('PUT: $url');
      print('Data: ${json.encode(data)}');
      
      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('PUT Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // DELETE Request
  Future<Map<String, dynamic>> delete(String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('DELETE: $url');
      
      final response = await http.delete(
        url, 
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // POST Multipart Request for file upload
  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('POST Multipart: $url');
      
      final request = http.MultipartRequest('POST', url);
      
      // Add headers (except Content-Type - multipart sets this automatically)
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      
      // Add fields
      request.fields.addAll(fields);
      
      // Detect content type from filename
      String? mimeType;
      if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      print('POST Multipart Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // PUT Multipart Request for file upload
  Future<Map<String, dynamic>> putMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('PUT Multipart: $url');
      
      final request = http.MultipartRequest('PUT', url);
      
      // Add headers
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      
      // Add fields
      request.fields.addAll(fields);
      
      // Detect content type from filename
      String? mimeType;
      if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      print('PUT Multipart Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');

    final dynamic data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // For error responses, extract message from Map
      final errorMessage = data is Map<String, dynamic> 
          ? data['message'] 
          : 'Lỗi không xác định';
      
      if (response.statusCode == 401) {
        throw UnauthorizedException(errorMessage ?? 'Phiên đăng nhập hết hạn');
      } else if (response.statusCode == 404) {
        throw NotFoundException(errorMessage ?? 'Không tìm thấy dữ liệu');
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw BadRequestException(errorMessage ?? 'Yêu cầu không hợp lệ');
      } else {
        throw ServerException(errorMessage ?? 'Lỗi server');
      }
    }
  }
}

// Custom Exceptions
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}