import 'package:flutter/material.dart';
import 'package:hamyar/services/auth_service.dart';
import 'package:hamyar/services/number_converter.dart';
import 'package:provider/provider.dart';
import 'package:hamyar/providers/user_provider.dart';
import 'package:hamyar/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CompleteProfilePage extends StatefulWidget {
  final String phone;

  const CompleteProfilePage({
    super.key,
    required this.phone,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String _errorMessage = '';

  // مقدار جنسیت که API توی getProfile برمی‌گردونه معمولاً 'M' یا 'F' هست، 
  // پس مقدار پیش‌فرض رو هم اینجا 'M' گذاشتم (قبلاً اشتباها 'male' بود)
  String? _selectedGender = 'M';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final profile = await AuthService.getProfile();

      if (profile.containsKey('first_name')) {
        _firstNameController.text = profile['first_name'] ?? '';
      }
      if (profile.containsKey('last_name')) {
        _lastNameController.text = profile['last_name'] ?? '';
      }
      if (profile.containsKey('gender')) {
        setState(() {
          _selectedGender = profile['gender'];
        });
      }
    } catch (e) {
      print('خطا در بارگذاری پروفایل: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تکمیل پروفایل')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text('شماره شما: ${convertEnglishDigitsToPersian(widget.phone)}'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'نام'),
                        validator: (value) => (value == null || value.isEmpty) ? 'نام را وارد کنید' : null,
                      ),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'نام خانوادگی'),
                        validator: (value) => (value == null || value.isEmpty) ? 'نام خانوادگی را وارد کنید' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: 'جنسیت'),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('مرد')),
                          DropdownMenuItem(value: 'F', child: Text('زن')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) => (value == null || value.isEmpty) ? 'جنسیت را انتخاب کنید' : null,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'رمز عبور'),
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        validator: (value) => (value == null || value.length < 4) ? 'رمز باید حداقل ۴ رقم باشد' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : submitProfile,
                        child: const Text('ثبت اطلاعات'),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red, fontFamily: 'Vazir'),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await AuthService.completeProfile(
        phone: widget.phone,
        firstName: convertPersianDigitsToEnglish(_firstNameController.text.trim()),
        lastName: convertPersianDigitsToEnglish(_lastNameController.text.trim()),
        password: convertPersianDigitsToEnglish(_passwordController.text.trim()),
        gender: _selectedGender,
      );

      // دریافت اطلاعات جدید
      final updatedProfile = await AuthService.getProfile();

      // گرفتن توکن از SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      // ذخیره کاربر در Provider
      Provider.of<UserProvider>(context, listen: false)
          .setUser(User.fromJson(updatedProfile), token: token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اطلاعات با موفقیت ثبت شد')),
      );

      // رفتن به صفحه اصلی و حذف تاریخچه صفحات قبلی
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }



}
