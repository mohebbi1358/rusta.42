import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../news/news_detail_page.dart';
import '../news/widgets/news_list_widget.dart';
import 'home_page.dart';
import '../accounts/dashboard_page.dart';
import '../martyrs/martyr_list_page.dart';

/// هر صفحه‌ای که عنوان داشته باشد این را پیاده‌سازی کند
abstract class PageWithTitle {
  String get pageTitle;
}

class AppShell extends StatefulWidget {
  final int initialIndex;
  final Widget? child;

  const AppShell({this.initialIndex = 0, this.child, super.key});

  @override
  State<AppShell> createState() => _AppShellState();

  static _AppShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AppShellState>();
  }
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  Widget? _embeddedPage;

  static const List<String> _tabTitles = [
    'خانه',
    'جاودانه‌ها',
    'صدقه',
    'کیف پول',
    'اخبار',
    'داشبورد',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// برای وقتی که یک صفحهٔ embedded عنوانش بعداً تغییر می‌کند
  void refreshTitle() {
    if (mounted) setState(() {});
  }

  void setTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _embeddedPage = null;
    });
  }

  void openEmbeddedPage(Widget page) {
    setState(() {
      _embeddedPage = page;
    });
  }

  void closeEmbeddedPage() {
    setState(() {
      _embeddedPage = null;
    });
  }

  /// بدنهٔ واقعی صفحه
  Widget _buildBody() {
    if (_embeddedPage != null) return _embeddedPage!;
    if (widget.child != null) return widget.child!;
    return _pageForIndex(_currentIndex);
  }

  /// فقط برای محاسبهٔ عنوان (بدون side-effect)
  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return HomePage(onNavigateTab: setTab);
      case 1:
        return const MartyrListPage();
      case 2:
        return const Center(child: Text("صدقه (در دست ساخت)"));
      case 3:
        return const Center(child: Text("کیف پول (در دست ساخت)"));
      case 4:
        return NewsListWidget(
          onNewsTap: (news) =>
              openEmbeddedPage(NewsDetailPage(news: news, embedded: true)),
        );
      case 5:
        return const DashboardPage();
      default:
        return const Center(child: Text("صفحه در دست ساخت"));
    }
  }

  /// عنوان جاری نوار بالا
  String _currentPageTitle() {
    // 1) اگر صفحهٔ embedded داریم و عنوان‌دار است
    if (_embeddedPage is PageWithTitle) {
      return (_embeddedPage as PageWithTitle).pageTitle;
    }
    // 2) اگر child مستقیم دادیم و عنوان‌دار است
    if (widget.child is PageWithTitle) {
      return (widget.child as PageWithTitle).pageTitle;
    }
    // 3) از صفحهٔ تب فعلی (اگر عنوان‌دار است)
    final body = _pageForIndex(_currentIndex);
    if (body is PageWithTitle) {
      return (body as PageWithTitle).pageTitle;
    }
    // 4) fallback: عنوان تب
    if (_currentIndex >= 0 && _currentIndex < _tabTitles.length) {
      return _tabTitles[_currentIndex];
    }
    return 'صفحه';
  }

  Future<bool> _onWillPop() async {
    if (_embeddedPage != null) {
      closeEmbeddedPage();
      return false;
    }
    if (_currentIndex != 0) {
      setTab(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final username =
        (user?.fullName.isNotEmpty == true) ? user!.fullName : 'کاربر ناشناس';
    final pageTitle = _currentPageTitle();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            leading: _embeddedPage != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: closeEmbeddedPage,
                  )
                : null,
            titleSpacing: 0,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'خیریه فردوس برین فردو - $pageTitle',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.message),
                  onSelected: (value) {
                    switch (value) {
                      case 'unread':
                        setTab(4);
                        break;
                      case 'read':
                        setTab(5);
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'unread', child: Text('پیام‌های خوانده نشده')),
                    PopupMenuItem(
                        value: 'read', child: Text('پیام‌های خوانده شده')),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setTab(5),
                  child: Text(
                    username,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
            onTap: setTab,
            selectedItemColor: Colors.indigo,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'خانه'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'جاودانه‌ها'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.volunteer_activism), label: 'صدقه'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet), label: 'کیف پول'),
              BottomNavigationBarItem(icon: Icon(Icons.article), label: 'اخبار'),
            ],
          ),
        ),
      ),
    );
  }
}
