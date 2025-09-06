class Martyr {
  final int id;
  final String firstName;
  final String lastName;
  final String? fatherName;
  final String? birthPlace;
  final String? birthDate;
  final String? lastOperation;
  final String? martyrRegion;
  final String? martyrPlace;
  final String? martyrDate;
  final String? gravePlace;
  final String? photo;

  Martyr({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.fatherName,
    this.birthPlace,
    this.birthDate,
    this.lastOperation,
    this.martyrRegion,
    this.martyrPlace,
    this.martyrDate,
    this.gravePlace,
    this.photo,
  });

  factory Martyr.fromJson(Map<String, dynamic> json) {
    return Martyr(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fatherName: json['father_name'],
      birthPlace: json['birth_place'],
      birthDate: json['birth_date'],
      lastOperation: json['last_operation'],
      martyrRegion: json['martyr_region'],
      martyrPlace: json['martyr_place'],
      martyrDate: json['martyr_date'],
      gravePlace: json['grave_place'],
      photo: json['photo'],
    );
  }
}
