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
        .toList()
      ?? [],
      createdAt: DateTime.parse(json['created_at']),
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
