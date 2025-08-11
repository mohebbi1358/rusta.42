import 'package:flutter/material.dart';
import 'package:hamyar/routes/account_routes.dart';
import 'package:hamyar/screens/home_page.dart';

class MainRoutes {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // اول بررسی مسیرهای Account
    final accountRoute = AccountRoutes.generateRoute(settings);
    if (accountRoute != null) return accountRoute;

    // مسیرهای دیگر
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());

      // دیگر مسیرها اینجا اضافه می‌شن

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('صفحه پیدا نشد')),
            body: const Center(child: Text('مسیر مورد نظر یافت نشد')),
          ),
        );

    }
  }
}
