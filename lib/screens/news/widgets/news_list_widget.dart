// lib/screens/news/widgets/news_list_widget.dart
import 'package:flutter/material.dart';
import '../../../models/news.dart';
import '../../../services/news_service.dart';
import '../news_detail_page.dart';

class NewsListWidget extends StatefulWidget {
  final void Function(News)? onNewsTap; // اختیاری: اگر داده نشد → push می‌کند

  const NewsListWidget({super.key, this.onNewsTap});

  @override
  _NewsListWidgetState createState() => _NewsListWidgetState();
}

class _NewsListWidgetState extends State<NewsListWidget> {
  List<Category> categories = [];
  List<News> newsList = [];
  int? selectedCategoryId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndNews();
  }

  Future<void> _fetchCategoriesAndNews() async {
    setState(() => isLoading = true);
    try {
      categories = await NewsService.getCategories();
      newsList = await NewsService.getNews();
      // ترتیب بر اساس تاریخ معکوس (جدیدترین اول)
      newsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchNewsByCategory(int? categoryId) async {
    setState(() {
      selectedCategoryId = categoryId;
      isLoading = true;
    });

    try {
      List<News> fetchedNews = await NewsService.getNews(
        categoryId: categoryId,
      );
      // ترتیب بر اساس تاریخ معکوس
      fetchedNews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() => newsList = fetchedNews);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _handleTap(News news) {
    if (widget.onNewsTap != null) {
      widget.onNewsTap!(news);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsDetailPage(news: news)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // فیلتر دسته‌بندی
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<int?>(
            value: selectedCategoryId,
            isExpanded: true,
            hint: const Text("همه دسته‌ها"),
            items: [
              const DropdownMenuItem(value: null, child: Text("همه")),
              ...categories.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                ),
              ),
            ],
            onChanged: (int? newValue) {
              if (newValue != selectedCategoryId) {
                _fetchNewsByCategory(newValue);
              }
            },
          ),
        ),
        // لیست اخبار
        Expanded(
          child: newsList.isEmpty
              ? const Center(child: Text("هیچ خبری موجود نیست"))
              : ListView.builder(
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final news = newsList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () => _handleTap(news),
                        child: Row(
                          children: [
                            if (news.mainImage.isNotEmpty)
                              Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.all(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(news.mainImage, fit: BoxFit.cover),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      news.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'دسته: ${news.categoryName}',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      news.summary.replaceAll(RegExp(r'\s+'), ' '),
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
