import 'package:flutter/material.dart';


class BasePage extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabTapped;
  final String username;

  const BasePage({
    required this.body,
    required this.currentIndex,
    required this.onTabTapped,
    required this.username,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'خیریه فردوس برین فردو',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.message),
              onSelected: (value) {
                // کنترل مسیج‌ها اینجا قرار می‌گیره
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('انتخاب شد: $value')),
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unread',
                  child: Text('پیام‌های خوانده نشده'),
                ),
                const PopupMenuItem(
                  value: 'read',
                  child: Text('پیام‌های خوانده شده'),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: Text(
                username,
                style: const TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline, // اختیاری، برای اینکه کاربر بفهمه کلیک‌پذیره
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'جاودانه‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'صدقه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'کیف پول',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'اخبار',
          ),
        ],
      ),

    );
  }
}
