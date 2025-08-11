import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiClient {
  // چون AuthService هم از ApiClient استفاده می‌کنه،
  // اینجا بهتره مقدار مستقیم یا از کانفیگ بیاد
  static const String baseUrl = "https://example.com"; // آدرس واقعی سرور

  static Future<http.Response> get(String endpoint) async {
    return await _sendWithRetry(() async => await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
        ));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    return await _sendWithRetry(() async => await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        ));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    return await _sendWithRetry(() async => await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        ));
  }

  static Future<http.Response> delete(String endpoint) async {
    return await _sendWithRetry(() async => await http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
        ));
  }

  // 🧠 مدیریت رفرش توکن در صورت نیاز
  static Future<http.Response> _sendWithRetry(Future<http.Response> Function() request) async {
    http.Response response = await request();

    if (response.statusCode == 401) {
      final newToken = await AuthService.refreshAccessToken();
      if (newToken != null) {
        // ✅ با توکن جدید دوباره تلاش کن
        response = await request();
      }
    }

    return response;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }
}
