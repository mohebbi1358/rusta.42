// lib/services/user_service.dart
import 'dart:convert';
import 'api_client.dart';

class UserService {
  /// لیست نام دسته‌بندی‌های مجاز کاربر
  static Future<List<String>> getUserCategories(String phone) async {
    final response = await ApiClient.get('/api/allowed-categories/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<String>((item) => item['name'] as String).toList();
    } else {
      throw Exception('Failed to fetch user categories');
    }
  }
}
