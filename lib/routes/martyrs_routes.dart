// lib/routes/martyrs_routes.dart
import 'package:flutter/material.dart';
import '../screens/martyrs/martyr_detail_page.dart';
import '../screens/martyrs/martyr_list_page.dart';
import '../screens/martyrs/martyr_memory_page.dart';

class MartyrRoutes {
  static const String martyrList = '/martyr-list';
  static const String martyrDetail = '/martyr-detail';
  static const String martyrMemory = '/martyr-memory';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // لیست شهدا
      case martyrList:
        return MaterialPageRoute(
          builder: (_) => const MartyrListPage(),
        );

      // جزئیات شهید
      case martyrDetail:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final martyrId = args['id'];
          return MaterialPageRoute(
            builder: (_) => MartyrDetailPage(martyrId: martyrId),
          );
        }
        return null;

      // دل‌نوشته‌ها
      case martyrMemory:
        if (settings.arguments is int) {
          final martyrId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => MartyrMemoryPage(martyrId: martyrId),
          );
        }
        return null;

      default:
        return null;
    }
  }
}
