import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
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

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
// GET Request
  Future<Map<String, dynamic>> get(String endpoint) async {
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
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('DELETE: $url');
      
      final response = await http.delete(url, headers: _headers);
      
      return _handleResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');

    final Map<String, dynamic> data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException(data['message'] ?? 'Phiên đăng nhập hết hạn');
    } else if (response.statusCode == 404) {
      throw NotFoundException(data['message'] ?? 'Không tìm thấy dữ liệu');
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      throw BadRequestException(data['message'] ?? 'Yêu cầu không hợp lệ');
    } else {
      throw ServerException(data['message'] ?? 'Lỗi server');
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