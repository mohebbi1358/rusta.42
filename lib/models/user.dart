import 'news.dart'; // Category اینجا هست

class User {
  final String phone;
  final String firstName;
  final String lastName;
  final String? gender;
  final List<Category> categories; // حالا لیست Category است

  User({
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.gender,
    required this.categories,
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
      gender: json['gender'],
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
    String? gender,
    List<Category>? categories,
  }) {
    return User(
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      categories: categories ?? this.categories,
    );
  }
}
