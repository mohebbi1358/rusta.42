import 'package:flutter/material.dart';
import 'widgets/shahed_card.dart';

class HomePage extends StatelessWidget {
  final void Function(int) onNavigateTab;
  const HomePage({required this.onNavigateTab, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ShahedCard(
          onTap: () => onNavigateTab(1), // بفرست به تب "جاودانه‌ها"
        ),
      ],
    );
  }
}
