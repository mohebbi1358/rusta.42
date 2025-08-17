import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'routes/main_routes.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs();

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

      // تنظیمات زبان فارسی و RTL
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme یکپارچه با فونت و رنگ بندی
      theme: ThemeData(
        fontFamily: 'Vazir',
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 1,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),

      // مسیر اولیه با توجه به وضعیت ورود
      initialRoute: isLoggedIn ? '/home' : '/login',
      onGenerateRoute: MainRoutes.generateRoute,
    );
  }
}
