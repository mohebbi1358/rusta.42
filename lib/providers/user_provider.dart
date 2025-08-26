import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../models/news.dart'; // اضافه کردن برای Category

class UserProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoadingCategories = false; // وضعیت بارگذاری دسته‌بندی‌ها

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && _token != null;
  bool get isLoadingCategories => _isLoadingCategories;

  // تنظیم کاربر بعد از ورود
  Future<void> setUser(User user, {required String token}) async {
    _user = user;
    _token = token;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('phone', user.phone);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);

    await fetchAllowedCategories();
  }

  // بارگذاری کاربر از SharedPreferences
  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final phone = prefs.getString('phone');
    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';

    if (token != null && phone != null) {
      _user = User(
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        gender: null,
        categories: [],
      );
      _token = token;

      // لود دسته‌بندی‌ها از API
      await fetchAllowedCategories();
    }
  }

  // پاک کردن کاربر
  Future<void> clearUser() async {
    _user = null;
    _token = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // بروزرسانی اطلاعات کاربر
  void updateUser({required String firstName, required String lastName, String? gender}) {
    if (_user == null) return;

    _user = _user!.copyWith(
      firstName: firstName,
      lastName: lastName,
      gender: gender ?? _user!.gender,
    );
    notifyListeners();
  }

  // بارگذاری دسته‌بندی‌های مجاز از API
  Future<void> fetchAllowedCategories() async {
    if (_user == null) return;

    _isLoadingCategories = true;
    notifyListeners();

    try {
      // دریافت لیست Category از سرویس
      List<Category> fetchedCategories = await UserService.getUserCategories();

      _user = _user!.copyWith(categories: fetchedCategories);

      print("Fetched categories: ${_user!.categories.map((c) => c.name).toList()}");
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      _user = _user!.copyWith(categories: []);
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }


}
