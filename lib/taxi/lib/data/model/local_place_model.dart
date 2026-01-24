class LocalPlaceModel {
  final String name;
  final String details;
  final double lat;
  final double lng;
  final String type; // place, street, region

  LocalPlaceModel({
    required this.name,
    required this.details,
    required this.lat,
    required this.lng,
    this.type = 'unknown',
  });

  factory LocalPlaceModel.fromJson(Map<String, dynamic> json) {
    return LocalPlaceModel(
      // نستقبل البيانات من سيرفرك
      name: json['place_name'] ?? json['name'] ?? '',
      details: json['neighborhood'] ?? json['details'] ?? '',
      lat: double.parse((json['lat'] ?? 0).toString()),
      lng: double.parse((json['lng'] ?? 0).toString()),
      type: json['type'] ?? 'place',
    );
  }
}