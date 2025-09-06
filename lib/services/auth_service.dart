import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamyar/services/number_converter.dart';
import 'package:hamyar/services/api_client.dart';

class AuthService {
  // از const به final تغییر کرد تا حلقه وابستگی حذف شود
  static final String baseUrl = ApiClient.baseUrl;

  // -------------------------------
  // لاگین با رمز عبور
  static Future<Map<String, dynamic>> loginWithPassword(String phone, String password) async {
    final response = await ApiClient.post('/api/login/', {
      'phone': convertPersianDigitsToEnglish(phone.trim()),
      'password': convertPersianDigitsToEnglish(password.trim()),
      'action': 'login_password',
    }, withAuth: false);  // بدون هدر Authorization

    final data = _processResponse(response);
    await _storeTokensIfExists(data);
    return data;
  }


  // -------------------------------
  // ارسال کد پیامکی
  static Future<Map<String, dynamic>> sendCode(String phone) async {
    final response = await ApiClient.post('/api/login/', {
      'phone': convertPersianDigitsToEnglish(phone.trim()),
      'action': 'send_code',
    });

    return _processResponse(response);
  }

  // -------------------------------
  // تأیید کد پیامکی
  static Future<Map<String, dynamic>> verifyCode(String phone, String code) async {
    final response = await ApiClient.post('/api/verify-code/', {
      'phone': convertPersianDigitsToEnglish(phone.trim()),
      'code': convertPersianDigitsToEnglish(code.trim()),
    });

    final data = _processResponse(response);
    await _storeTokensIfExists(data);
    return data;
  }

  // -------------------------------
  // دریافت پروفایل
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiClient.get('/api/complete-profile/');
    return _processResponse(response);
  }

  // -------------------------------
  // تکمیل پروفایل
  static Future<void> completeProfile({
    required String phone,
    required String firstName,
    required String lastName,
    required String fatherName,
    required String password,
    String? gender,
    String? imageBase64,
  }) async {
    final Map<String, dynamic> body = {
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'father_name': fatherName,
      'password': password,
      'gender': gender ?? 'M',
    };

    if (imageBase64 != null) {
      body['image'] = imageBase64;
    }

    // لاگ قبل از ارسال
    print("POST /api/complete-profile/ body:");
    print("Keys: ${body.keys}");
    print("ImageBase64 length: ${imageBase64?.length ?? 0}");

    final response = await ApiClient.post('/api/complete-profile/', body);

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    _processResponse(response);
  }




  // -------------------------------
  // تمدید توکن
  static Future<String?> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh_token');
    if (refresh == null) return null;

    final response = await ApiClient.post('/api/token/refresh/', {'refresh': refresh});

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      await prefs.setString('access_token', data['access']);
      return data['access'];
    } else {
      await logout();
      return null;
    }
  }

  // -------------------------------
  // لاگ‌اوت
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // -------------------------------
  // ذخیره توکن‌ها اگر وجود داشت
  static Future<void> _storeTokensIfExists(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data.containsKey('access')) {
      await prefs.setString('access_token', data['access']);
    }
    if (data.containsKey('refresh')) {
      await prefs.setString('refresh_token', data['refresh']);
    }
  }

  // -------------------------------
  // پردازش پاسخ دریافتی
  static Map<String, dynamic> _processResponse(response) {
    final contentType = response.headers['content-type'];
    if (contentType == null || !contentType.contains('application/json')) {
      throw Exception('پاسخ دریافتی JSON نیست: $contentType');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> data = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'خطای ناشناس از سرور');
    }
  }
}
