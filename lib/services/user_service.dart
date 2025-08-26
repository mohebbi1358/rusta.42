// lib/services/user_service.dart
import 'dart:convert';
import 'api_client.dart';
import '../models/news.dart';

class UserService {
  /// لیست دسته‌بندی‌های مجاز کاربر
  static Future<List<Category>> getUserCategories() async {
    final response = await ApiClient.get('/api/allowed-categories/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<Category>((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch user categories');
    }
  }
}

