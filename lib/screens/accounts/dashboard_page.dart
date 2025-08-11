import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hamyar/providers/user_provider.dart'; // ✅
import 'package:hamyar/routes/account_routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      // اگر به هر دلیلی کاربر null بود، برگرد به صفحه لاگین
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AccountRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد کاربر'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'سلام ${user.fullName} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AccountRoutes.completeProfile,
                  arguments: {'phone': user.phone},
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('تکمیل پروفایل'),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                userProvider.clearUser();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AccountRoutes.login,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('خروج از حساب کاربری'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
