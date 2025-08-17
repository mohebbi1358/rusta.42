import 'package:flutter/material.dart';
import 'package:hamyar/screens/accounts/login_page.dart' as login_page;
import 'package:hamyar/screens/accounts/verify_code_page.dart' as verify;
import 'package:hamyar/screens/accounts/complete_profile_page.dart';
import '../screens/main/app_shell.dart';

class AccountRoutes {
  static const String login = '/login';
  static const String verifyCode = '/verify-code';
  static const String completeProfile = '/complete-profile';
  static const String dashboard = '/dashboard';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const login_page.LoginPage());

      case verifyCode:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('phone')) {
          return _errorRoute('شماره تلفن برای verifyCode ارسال نشده است.');
        }
        return MaterialPageRoute(
          builder: (_) => verify.VerifyCodePage(phone: args['phone']),
        );

      case completeProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('phone')) {
          return _errorRoute('شماره تلفن برای completeProfile ارسال نشده است.');
        }
        return MaterialPageRoute(
          builder: (_) => CompleteProfilePage(phone: args['phone']),
        );

      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const AppShell(initialIndex: 5),
        );

      default:
        return null;
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('خطا')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
