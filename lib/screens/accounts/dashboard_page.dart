import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hamyar/providers/user_provider.dart';
import 'package:hamyar/routes/account_routes.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      await userProvider.fetchAllowedCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AccountRoutes.login);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLoadingCategories = userProvider.isLoadingCategories;
    final hasCategoryAccess = !isLoadingCategories && user.categories.isNotEmpty;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "سلام ${user.fullName.isNotEmpty ? user.fullName : "کاربر ناشناس"} 👋",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // دکمه تکمیل پروفایل
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AccountRoutes.completeProfile,
                  arguments: {'phone': user.phone ?? ''},
                );
                if (result != null && result is Map<String, dynamic>) {
                  userProvider.updateUser(
                    firstName: result['firstName'] ?? user.firstName,
                    lastName: result['lastName'] ?? user.lastName,
                    fatherName: result['fatherName'] ?? user.fatherName ?? '',
                    gender: result['gender'] ?? user.gender,
                  );
                }
              },
              icon: const Icon(Icons.person),
              label: const Text('تکمیل پروفایل'),
            ),
            const SizedBox(height: 16),

            // دکمه ارسال خبر
            ElevatedButton.icon(
              onPressed: hasCategoryAccess
                  ? () {
                      Navigator.pushNamed(context, '/create-news');
                    }
                  : null,
              icon: const Icon(Icons.send),
              label: const Text('ارسال خبر'),
            ),
            const SizedBox(height: 16),

            // دکمه خروج
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
              label: const Text("خروج از حساب"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),

            if (isLoadingCategories)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
