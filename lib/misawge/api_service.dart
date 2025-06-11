import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://your-site.com/wp-json/wc/v3';
  static const String _consumerKey = 'ck_your_key_here'; // استبدلها بمفتاحك
  static const String _consumerSecret = 'cs_your_secret_here'; // استبدلها بسريتك

  static Future<List<dynamic>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products?consumer_key=$_consumerKey&consumer_secret=$_consumerSecret'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}