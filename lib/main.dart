import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/main_routes.dart';
import 'providers/user_provider.dart'; // آدرس نسبت به ساختار پروژه‌ات

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs(); // ⬅️ لود اطلاعات ذخیره‌شده

  runApp(
    ChangeNotifierProvider(
      create: (_) => userProvider,
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Provider.of<UserProvider>(context).isLoggedIn;

    return MaterialApp(
      title: 'Hamyar App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: isLoggedIn ? '/home' : '/login', // یا complete-profile اگه می‌خوای
      onGenerateRoute: MainRoutes.generateRoute,
    );
  }
}
