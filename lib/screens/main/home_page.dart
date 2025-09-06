import 'package:flutter/material.dart';
import 'widgets/shahed_card.dart';
// مسیر روت‌های شهدا
import '../main/app_shell.dart';

class HomePage extends StatelessWidget {
  final void Function(int) onNavigateTab;
  const HomePage({required this.onNavigateTab, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ShahedCard(
          onTap: () {
            final shell = AppShell.of(context);
            if (shell != null) {
              shell.setTab(1); // تب شماره ۱ مربوط به "جاودانه‌ها" یا لیست شهدا
            }
          }
        ),
      ],
    );
  }
}
