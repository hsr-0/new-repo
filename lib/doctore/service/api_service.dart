import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appoinminet.dart';
import '../models/docto.dart';

class ApiService {
  static const String _baseUrl = 'https://antiquewhite-boar-752646.hostingersite.com/wp-json';

  // تسجيل الدخول
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/jwt-auth/v1/token'),
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('فشل تسجيل الدخول');
    }
  }

  // تسجيل مستخدم جديد
  static Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/wp/v2/users/register'),
      body: {
        'username': email,
        'email': email,
        'password': password,
        'name': name,
      },
    );

    return response.statusCode == 200;
  }

  // الحصول على قائمة الأطباء
  static Future<List<Doctor>> getDoctors() async {
    final response = await http.get(Uri.parse('$_baseUrl/wp/v2/doctors'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Doctor.fromJson(json)).toList();
    } else {
      throw Exception('فشل تحميل بيانات الأطباء');
    }
  }

  // حجز موعد
  static Future<bool> bookAppointment(int doctorId, String date, String time) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$_baseUrl/wp/v2/appointments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': 'حجز موعد',
        'status': 'publish',
        'fields': {
          'doctor': doctorId,
          'date_time': '$date $time',
          'status': 'pending',
        },
      }),
    );

    return response.statusCode == 201;
  }

  // الحصول على حجوزات المستخدم
  static Future<List<Appointment>> getUserAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$_baseUrl/wp/v2/appointments?patient=${prefs.getInt('userId')}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Appointment.fromJson(json)).toList();
    } else {
      throw Exception('فشل تحميل الحجوزات');
    }
  }

  static cancelAppointment(int appointmentId) {}
}