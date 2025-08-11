import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/number_converter.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

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

  Future<void> submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final token = userProvider.token;
      if (token == null) throw Exception('توکن پیدا نشد. لطفاً دوباره وارد شوید.');

      final phone = userProvider.user?.phone;
      if (phone == null) throw Exception('شماره کاربر پیدا نشد.');

      await AuthService.completeProfile(
        token: token,
        firstName: convertPersianDigitsToEnglish(_firstNameController.text.trim()),
        lastName: convertPersianDigitsToEnglish(_lastNameController.text.trim()),
        password: convertPersianDigitsToEnglish(_passwordController.text.trim()),
      );

      // بعد از موفقیت:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اطلاعات با موفقیت ثبت شد')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPhone = Provider.of<UserProvider>(context).user?.phone ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تکمیل پروفایل')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text('شماره شما: ${convertEnglishDigitsToPersian(userPhone)}'),
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

                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'رمز عبور'),
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  validator: (value) =>
                      (value == null || value.length < 4) ? 'رمز باید حداقل ۴ رقم باشد' : null,
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

                if (_loading) const SizedBox(height: 16),
                if (_loading) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
