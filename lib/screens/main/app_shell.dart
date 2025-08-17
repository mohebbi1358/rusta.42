// lib/screens/main/app_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'home_page.dart';
import '../accounts/dashboard_page.dart';
import '../news/widgets/news_list_widget.dart';
import '../news/news_detail_page.dart';
import '../../models/news.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  final Widget? child; // اگر بخوای صفحه‌ای را مستقیم داخل shell باز کنی

  const AppShell({this.initialIndex = 0, this.child, super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  News? _detailNews; // اگر خبری برای نمایش جزئیات انتخاب شود اینجا قرار می‌گیرد

  static const List<String> _tabTitles = [
    'خانه',
    'جاودانه‌ها',
    'صدقه',
    'کیف پول',
    'اخبار',
    'داشبورد'
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _setTab(int index) {
    setState(() {
      _currentIndex = index;
      _detailNews = null; // وقتی تب عوض می‌شود، جزئیات بسته شود
    });
  }

  void _openNewsDetail(News news) {
    setState(() {
      _detailNews = news;
    });
  }

  void _closeNewsDetail() {
    setState(() {
      _detailNews = null;
    });
  }

  Widget _buildBody() {
    // اگر صفحه جزئیات باز است، محتوای embedded جزئیات باز می‌شود (بدون Scaffold داخلی)
    if (_detailNews != null) {
      return NewsDetailPage(news: _detailNews!, embedded: true);
    }

    // اگر child مشخص شده باشد، آن را نمایش بده
    if (widget.child != null) return widget.child!;

    // تب‌ها (HomePage و غیره)
    switch (_currentIndex) {
      case 0:
        // HomePage باید ورودی onNavigateTab داشته باشه تا بتونه تب‌ها رو عوض کنه
        return HomePage(onNavigateTab: _setTab);
      case 1:
        return const Center(child: Text("جاودانه‌ها (در دست ساخت)"));
      case 2:
        return const Center(child: Text("صدقه (در دست ساخت)"));
      case 3:
        return const Center(child: Text("کیف پول (در دست ساخت)"));
      case 4:
        return NewsListWidget(onNewsTap: _openNewsDetail);
      case 5:
        return const DashboardPage();
      default:
        return const Center(child: Text("صفحه در دست ساخت"));
    }
  }

  String _currentPageTitle() {
    if (_detailNews != null) return 'جزئیات خبر';
    if (widget.child != null) {
      // اگر بخوای می‌تونی اینجا چک کنی اگر widget.child از یک اینترفیس pageTitle پیروی می‌کنه
      return 'صفحه';
    }
    if (_currentIndex >= 0 && _currentIndex < _tabTitles.length) {
      return _tabTitles[_currentIndex];
    }
    return 'صفحه';
  }

  Future<bool> _onWillPop() async {
    if (_detailNews != null) {
      _closeNewsDetail();
      return false; // جلوگیری از خروج واقعی، فقط بسته شدن جزئیات
    }
    if (_currentIndex != 0) {
      _setTab(0);
      return false;
    }
    return true; // اجازه خروج اپ
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final username = (user?.fullName.isNotEmpty == true) ? user!.fullName : 'کاربر ناشناس';
    final pageTitle = _currentPageTitle();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            // اگر جزئیات باز است، دکمه back نمایش داده می‌شود و onPressed جزئیات را می‌بندد.
            leading: _detailNews != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _closeNewsDetail,
                  )
                : null,
            titleSpacing: 0,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'خیریه فردوس برین فردو - $pageTitle',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // منوی پیام‌ها (خوانده شده/خوانده نشده)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.message),
                  onSelected: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('انتخاب شد: $value')),
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'unread', child: Text('پیام‌های خوانده نشده')),
                    PopupMenuItem(value: 'read', child: Text('پیام‌های خوانده شده')),
                  ],
                ),

                const SizedBox(width: 8),

                // نام کاربر (کلیک => باز شدن داشبورد به صورت تب داخلی)
                GestureDetector(
                  onTap: () => _setTab(5),
                  child: Text(
                    username,
                    style: const TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // محتوای اصلی (تب‌ها یا جزئیات)
          body: _buildBody(),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
            onTap: _setTab,
            selectedItemColor: Colors.indigo,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'خانه'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'جاودانه‌ها'),
              BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'صدقه'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'کیف پول'),
              BottomNavigationBarItem(icon: Icon(Icons.article), label: 'اخبار'),
            ],
          ),
        ),
      ),
    );
  }
}
