import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:hamyar/models/user.dart';
import 'package:hamyar/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamyar/services/number_converter.dart';
import 'package:hamyar/widgets/app_version_info.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String errorMessage = '';

  Future<void> loginWithPassword() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final result = await AuthService.loginWithPassword(
        convertPersianDigitsToEnglish(phoneController.text.trim()),
        convertPersianDigitsToEnglish(passwordController.text.trim()),
      );

      final user = result['user'];
      final accessToken = result['access'];
      final refreshToken = result['refresh'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      Provider.of<UserProvider>(context, listen: false)
          .setUser(User.fromJson(user), token: accessToken);

      if (user['is_profile_completed']) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/complete-profile');
      }
    } catch (e) {
      setState(() {
        errorMessage = _parseError(e);
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> sendCode() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      await AuthService.sendCode(
        convertPersianDigitsToEnglish(phoneController.text.trim()),
      );

      Navigator.pushNamed(context, '/verify-code', arguments: {
        'phone': phoneController.text.trim(),
      });
    } catch (e) {
      setState(() {
        errorMessage = _parseError(e);
      });
    } finally {
      setState(() => loading = false);
    }
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    } else {
      return 'خطای ناشناخته';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'شماره موبایل'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'رمز عبور'),
                    obscureText: true,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: loading ? null : loginWithPassword,
                    child: const Text('ورود با رمز'),
                  ),
                  TextButton(
                    onPressed: loading ? null : sendCode,
                    child: const Text('ارسال کد پیامکی'),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontFamily: 'Vazir'),
                      ),
                    ),
                  if (loading) const SizedBox(height: 16),
                  if (loading) const CircularProgressIndicator(),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                AppVersionInfo(),
                SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
