import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiClient {
  static const String baseUrl = "http://192.168.1.100:8000"; // آدرس آی‌پی خودت

  static Future<http.Response> get(String endpoint, {bool withAuth = true}) async {
    return await _sendWithRetry(() async => await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(withAuth: withAuth),
        ));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool withAuth = true}) async {
    return await _sendWithRetry(() async => await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(withAuth: withAuth),
          body: jsonEncode(body),
        ));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool withAuth = true}) async {
    return await _sendWithRetry(() async => await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(withAuth: withAuth),
          body: jsonEncode(body),
        ));
  }

  static Future<http.Response> delete(String endpoint, {bool withAuth = true}) async {
    return await _sendWithRetry(() async => await http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(withAuth: withAuth),
        ));
  }

  static Future<http.Response> _sendWithRetry(Future<http.Response> Function() request) async {
    http.Response response = await request();

    if (response.statusCode == 401) {
      final newToken = await AuthService.refreshAccessToken();
      if (newToken != null) {
        response = await request();
      }
    }

    return response;
  }

  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';

    final headers = {
      'Content-Type': 'application/json',
    };

    if (withAuth && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }
}
