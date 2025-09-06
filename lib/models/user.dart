import 'news.dart'; // اگر Category اینجاست


class User {
  final String phone;
  final String firstName;
  final String lastName;
  final String? fatherName;  // ✅ اضافه شد
  final String? gender;
  final String? imageUrl;    // ✅ اضافه شد
  final List<Category> categories;
  final bool is_admin;        // ✅ اضافه شد

  User({
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.fatherName,
    this.gender,
    this.imageUrl,
    required this.categories,
    this.is_admin = false,     // ✅ مقدار پیش‌فرض
  });

  String get fullName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return phone;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      phone: json['phone'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fatherName: json['father_name'],           // ✅ اضافه شد
      gender: json['gender'],
      imageUrl: json['image'],                   // ✅ اضافه شد
      is_admin: json['is_admin'] ?? false,        // ✅ اضافه شد
      categories: (json['allowed_categories'] as List<dynamic>?)
              ?.map((cat) => Category.fromJson(cat))
              .toList() ??
          [],
    );
  }

  User copyWith({
    String? phone,
    String? firstName,
    String? lastName,
    String? fatherName,
    String? gender,
    String? imageUrl,
    List<Category>? categories,
    bool? is_admin,       // ✅ اضافه شد
  }) {
    return User(
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fatherName: fatherName ?? this.fatherName,
      gender: gender ?? this.gender,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      is_admin: is_admin ?? this.is_admin,  // ✅
    );
  }
}