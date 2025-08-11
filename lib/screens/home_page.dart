import '../widgets/shahed_card.dart';
import 'package:flutter/material.dart';
import 'base_page.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart'; // مسیر دقیق رو تنظیم کن

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return ListView(
          children: [
            ShahedCard(
              onTap: () {
                // وقتی کاربر روی "مشاهده همه" زد، بره به تب شهداء (مثلاً تب 1)
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
          ],
        );
      case 1:
        return const Center(child: Text('جاودانه‌ها'));
      case 2:
        return const Center(child: Text('صدقه'));
      case 3:
        return const Center(child: Text('کیف پول'));
      case 4:
        return const Center(child: Text('اخبار'));
      default:
        return const Center(child: Text('صفحه ناشناخته'));
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    final username = user != null && user.fullName.isNotEmpty
        ? user.fullName
        : 'کاربر ناشناس';

    return BasePage(
      body: _getBody(),
      currentIndex: _selectedIndex,
      onTabTapped: _onTabTapped,
      username: username,
    );
  }
}
