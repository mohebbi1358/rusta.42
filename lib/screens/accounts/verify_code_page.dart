import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hamyar/models/user.dart';
import 'package:hamyar/providers/user_provider.dart';
import 'package:hamyar/services/auth_service.dart';
import 'package:hamyar/services/number_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyCodePage extends StatefulWidget {
  final String phone;

  const VerifyCodePage({super.key, required this.phone});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final codeController = TextEditingController();

  bool loading = false;
  String errorMessage = '';

  Future<void> verifyCode() async {
    final code = convertPersianDigitsToEnglish(codeController.text.trim());

    if (code.isEmpty) {
      setState(() {
        errorMessage = 'کد پیامکی را وارد کنید.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final result = await AuthService.verifyCode(
        convertPersianDigitsToEnglish(widget.phone),
        code,
      );

      final user = result['user'];
      final accessToken = result['access'];
      final refreshToken = result['refresh'];

      // ذخیره در SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      // ذخیره در Provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUser(User.fromJson(user), token: accessToken);

      Navigator.pushReplacementNamed(context, '/complete-profile');
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
    }
    return 'خطای ناشناخته';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأیید کد پیامکی')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('کد پیامکی به ${widget.phone} ارسال شد'),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'کد پیامکی'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : verifyCode,
              child: const Text('تأیید'),
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
    );
  }
}
