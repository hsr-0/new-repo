import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';

class LocationSearchRepo {
  final ApiClient apiClient;
  // تأكد أن هذا الرابط هو رابط سيرفرك الصحيح
  final String _myServerBaseUrl = "https://taxi.beytei.com/api";

  LocationSearchRepo({required this.apiClient});

  Future<dynamic> searchAddressByLocationName({
    required String text,
    required Position? position,
  }) async {
    // تجهيز الرابط
    String url = '$_myServerBaseUrl/local-search?q=${Uri.encodeComponent(text)}';
    if (position != null) {
      url += '&lat=${position.latitude}&lng=${position.longitude}';
    }

    print("🚀 [Repo] جاري البحث: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print("📡 [Repo] كود الاستجابة: ${response.statusCode}");
      print("📦 [Repo] البيانات الخام: ${response.body}");

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        // نقبل success أو إذا كانت البيانات موجودة مباشرة
        if (decodedResponse['status'] == 'success' || decodedResponse['data'] != null) {
          final List<dynamic> localData = decodedResponse['data'] ?? [];
          print("✅ [Repo] وجدنا ${localData.length} نتيجة");

          return {'features': _convertLocalDataToMapboxFormat(localData)};
        }
      }
    } catch (e) {
      print("🔥 [Repo] خطأ في الاتصال: $e");
    }

    return {'features': []};
  }

  Future<String?> getActualAddress(double lat, double lng) async {
    final url = '$_myServerBaseUrl/get-location-info?lat=$lat&lng=$lng';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          return decoded['data']['name'];
        }
      }
    } catch (e) {
      print("❌ [Repo] خطأ العنوان: $e");
    }
    return "موقع محدد";
  }

  List<dynamic> _convertLocalDataToMapboxFormat(List<dynamic> localData) {
    return localData.map((place) {
      // تحويل آمن للأرقام
      double lat = double.tryParse(place['lat'].toString()) ?? 0.0;
      double lng = double.tryParse(place['lng'].toString()) ?? 0.0;

      return {
        "id": place['id'].toString(),
        "place_name": place['place_name'],
        "description": place['place_name'] + " - " + (place['neighborhood'] ?? ""),
        "center": [lng, lat],
        "geometry": {
          "coordinates": [lng, lat]
        },
        // علامة مميزة جداً لنلتقطها في الكنترولر
        "source": "MY_SERVER"
      };
    }).toList();
  }
}
