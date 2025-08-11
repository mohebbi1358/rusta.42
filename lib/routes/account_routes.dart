import 'package:flutter/material.dart';
import 'package:hamyar/screens/accounts/login_page.dart' as login_page;
import 'package:hamyar/screens/accounts/verify_code_page.dart' as verify;
import 'package:hamyar/screens/accounts/complete_profile_page.dart';
import 'package:hamyar/screens/accounts/dashboard_page.dart'; // اضافه کن بالای فایل


class AccountRoutes {
  static const String login = '/login';
  static const String verifyCode = '/verify-code';
  static const String completeProfile = '/complete-profile';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const login_page.LoginPage());

      case verifyCode:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => verify.VerifyCodePage(phone: args['phone']),
        );

      case completeProfile:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CompleteProfilePage(phone: args['phone']),
        );
        
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());


      default:
        return null;
    }
  }
}
