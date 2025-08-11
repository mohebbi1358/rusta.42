import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;

  bool get isLoggedIn => _user != null && _token != null;

  Future<void> setUser(User user, {required String token}) async {
    _user = user;
    _token = token;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('phone', user.phone);
    await prefs.setString('firstName', user.firstName!);
    }

  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final phone = prefs.getString('phone');

    if (token != null && phone != null) {
      _user = User(
        phone: phone,
        firstName: prefs.getString('firstName'),
      );
      _token = token;
      notifyListeners();
    }
  }

  Future<void> clearUser() async {
    _user = null;
    _token = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
