class User {
  final String phone;
  final String firstName;
  final String lastName;

  User({
    required this.phone,
    required this.firstName,
    required this.lastName,
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
    );
  }
}
