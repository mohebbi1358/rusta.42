import 'package:flutter/material.dart';
import 'package:hamyar/screens/news/news_form.dart';
import 'package:hamyar/screens/news/edit_news_page.dart';
import 'package:hamyar/screens/news/news_tab.dart';
import '../../models/news.dart';

class NewsRoutes {
  static const String createNews = '/create-news';
  static const String newsList = '/news-list';
  static const String editNews = '/edit-news'; // مسیر جدید ویرایش خبر

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case createNews:
        return MaterialPageRoute(builder: (_) => const CreateNewsPage());

      case editNews:
        if (settings.arguments is News) {
          final news = settings.arguments as News;
          return MaterialPageRoute(builder: (_) => EditNewsPage(news: news));
        }
        return null;

      case newsList:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('لیست خبرها')),
            body: const NewsTab(),
          ),
        );

      default:
        return null;
    }
  }
}
