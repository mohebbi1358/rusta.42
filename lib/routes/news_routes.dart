import 'package:flutter/material.dart';
import 'package:hamyar/screens/news/news_form.dart';
import 'package:hamyar/screens/news/news_tab.dart';

class NewsRoutes {
  static const String createNews = '/create-news';
  static const String newsList = '/news-list';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case createNews:
        return MaterialPageRoute(builder: (_) => const CreateNewsPage());
      case newsList:
        return MaterialPageRoute(builder: (_) => const NewsTab());
      default:
        return null;
    }
  }
}
