import 'package:flutter/material.dart';
import 'package:hamyar/routes/account_routes.dart';
import 'package:hamyar/routes/news_routes.dart';
import '../screens/main/app_shell.dart';

class MainRoutes {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // بررسی مسیرهای Account
    final accountRoute = AccountRoutes.generateRoute(settings);
    if (accountRoute != null) return accountRoute;

    // بررسی مسیرهای News
    final newsRoute = NewsRoutes.generateRoute(settings);
    if (newsRoute != null) return newsRoute;

    // مسیرهای عمومی
    switch (settings.name) {
      case '/':
      case '/home':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final initialIndex = args['initialIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => AppShell(initialIndex: initialIndex),
        );

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
