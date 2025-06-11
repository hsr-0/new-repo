class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String imageUrl;
  final String bio;
  final String phone;
  final String clinic;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.imageUrl,
    required this.bio,
    required this.phone,
    required this.clinic,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['title']['rendered'] ?? 'غير معروف',
      specialization: json['acf']['specialization'] ?? 'غير محدد',
      imageUrl: json['acf']['image_url'] ?? '',
      bio: json['content']['rendered'] ?? 'لا يوجد وصف',
      phone: json['acf']['phone'] ?? 'لا يوجد',
      clinic: json['acf']['clinic'] ?? 'غير معروفة',
    );
  }
}