


class News {
  final int id;
  final String title;
  final int categoryId;
  final String categoryName;
  final String summary;
  final String body;
  final String mainImage;
  final List<String> extraImages;
  final List<Map<String, String>> links;
  final DateTime createdAt;

  // 🔹 فیلدهای مربوط به نویسنده
  final int authorId;
  final String authorName;
  final bool isOwner;

  News({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.summary,
    required this.body,
    required this.mainImage,
    required this.extraImages,
    required this.links,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    required this.isOwner,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      categoryId: json['category'],
      categoryName: json['category_name'] ?? '',
      summary: json['summary'] ?? '',
      body: json['body'] ?? '',
      mainImage: json['main_image'] ?? '',
      extraImages: (json['images'] as List<dynamic>?)
              ?.map((img) => img['image'] as String)
              .toList() ??
          [],
      links: (json['links'] as List<dynamic>?)
              ?.map((link) => {
                    'title': (link['title'] ?? '').toString(),
                    'url': (link['url'] ?? '').toString(),
                  })
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'] ?? '',
      isOwner: json['is_owner'] ?? false,
    );
  }

  /// متد برای ایجاد یک نسخه‌ی جدید با تغییرات دلخواه
  News copyWith({
    String? summary,
    String? body,
    String? mainImage,
    List<String>? extraImages,
    List<Map<String, String>>? links,
  }) {
    return News(
      id: id,
      title: title,
      categoryId: categoryId,
      categoryName: categoryName,
      summary: summary ?? this.summary,
      body: body ?? this.body,
      mainImage: mainImage ?? this.mainImage,
      extraImages: extraImages ?? this.extraImages,
      links: links ?? this.links,
      createdAt: createdAt,
      authorId: authorId,
      authorName: authorName,
      isOwner: isOwner,
    );
  }
}







class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
