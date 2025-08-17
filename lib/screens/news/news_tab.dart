// lib/screens/news/news_tab.dart
import 'package:flutter/material.dart';
import 'news_detail_page.dart';
import 'widgets/news_list_widget.dart';
import '../../models/news.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  News? _selectedNews;

  void _openNewsDetail(News news) {
    setState(() {
      _selectedNews = news;
    });
  }

  void _closeNewsDetail() {
    setState(() {
      _selectedNews = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // اگر یک خبر انتخاب شده، صفحه جزئیات را نشان بده
    if (_selectedNews != null) {
      return NewsDetailPage(news: _selectedNews!);
    }

    // در حالت عادی لیست اخبار
    return NewsListWidget(
      onNewsTap: _openNewsDetail,
    );
  }
}
