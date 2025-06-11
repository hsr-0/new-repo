import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String _token = '';
  int _userId = 0;
  String _userName = '';

  bool get isLoggedIn => _isLoggedIn;
  String get token => _token;
  int get userId => _userId;
  String get userName => _userName;

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getString('token') != null;
    _token = prefs.getString('token') ?? '';
    _userId = prefs.getInt('userId') ?? 0;
    _userName = prefs.getString('userName') ?? '';
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      await prefs.setInt('userId', response['user_id']);
      await prefs.setString('userName', response['user_display_name']);

      _isLoggedIn = true;
      _token = response['token'];
      _userId = response['user_id'];
      _userName = response['user_display_name'];
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');

    _isLoggedIn = false;
    _token = '';
    _userId = 0;
    _userName = '';
    notifyListeners();
  }
}