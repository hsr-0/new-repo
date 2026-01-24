import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/local_place_model.dart';

class LocalMapService {
  // رابط سيرفرك
  final String baseUrl = "https://taxi.beytei.com/api";

  // 1. البحث بالنص (عندما يكتب المستخدم)
  Future<List<LocalPlaceModel>> searchPlaces(String query, {double? lat, double? lng}) async {
    String url = "$baseUrl/local-search?q=$query";
    if (lat != null) url += "&lat=$lat&lng=$lng";

    print("🚀 [LocalMapService] Searching: $url"); // طباعة للكونسل

    try {
      final response = await http.get(Uri.parse(url));
      print("📡 [LocalMapService] Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          print("✅ [LocalMapService] Found ${jsonResponse['data'].length} results");
          return (jsonResponse['data'] as List)
              .map((e) => LocalPlaceModel.fromJson(e))
              .toList();
        }
      } else {
        print("❌ [LocalMapService] Server Error: ${response.body}");
      }
    } catch (e) {
      print("🔥 [LocalMapService] Exception: $e");
    }
    return [];
  }

  // 2. البحث بالإحداثيات (عند تحريك الدبوس)
  Future<LocalPlaceModel?> getAddressFromCoords(double lat, double lng) async {
    String url = "$baseUrl/get-location-info?lat=$lat&lng=$lng";
    print("📍 [LocalMapService] Reverse Geocoding: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print("📥 [LocalMapService] Response: $jsonResponse");

        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];
          // إنشاء مودل من البيانات
          return LocalPlaceModel(
              name: data['name'],
              details: data['details'],
              lat: lat, // نرجع نفس الإحداثيات
              lng: lng,
              type: data['type']
          );
        }
      }
    } catch (e) {
      print("🔥 [LocalMapService] Reverse Geo Error: $e");
    }
    return null;
  }
}