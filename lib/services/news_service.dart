// lib/services/news_service.dart
import '../models/news.dart';
import 'api_client.dart';
import 'dart:convert';


class NewsService {
  static Future<List<Category>> getCategories() async {
    final response = await ApiClient.get('/api/categories/');
    final List data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Category.fromJson(json)).toList();
  }

  static Future<List<News>> getNews({int? categoryId}) async {
    String endpoint = '/api/news/';
    if (categoryId != null) {
      endpoint += '?category=$categoryId';  // ✅ درست شد
    }
    final response = await ApiClient.get(endpoint);
    final List data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => News.fromJson(json)).toList();
  }


}
