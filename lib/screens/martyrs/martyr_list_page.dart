import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../main/app_shell.dart';
import '../../models/martyr.dart';
import 'martyr_detail_page.dart';
import '../../services/api_client.dart';

class MartyrListPage extends StatefulWidget implements PageWithTitle {
  const MartyrListPage({super.key});

  @override
  String get pageTitle {
    print("📌 MartyrListPage.pageTitle called!");
    return "لیست شهدا";
  }

  @override
  State<MartyrListPage> createState() => _MartyrListPageState();
}

class _MartyrListPageState extends State<MartyrListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Martyr> _martyrs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print("📌 _MartyrListPageState.initState called");
    _fetchMartyrs();
  }

  Future<void> _fetchMartyrs({String query = ""}) async {
    print("🔄 _fetchMartyrs called with query='$query'");
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final res = await dio.get(
        '${ApiClient.baseUrl}/api/martyrs/',
        queryParameters: {'q': query},
      );
      final data = (res.data as List);
      setState(() {
        _martyrs = data.map((e) => Martyr.fromJson(e)).toList();
      });
      print("✅ Fetched ${_martyrs.length} martyrs");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت لیست شهدا: $e')),
        );
      }
      print("❌ Error fetching martyrs: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _performSearch() {
    print("🔍 _performSearch with '${_searchController.text}'");
    _fetchMartyrs(query: _searchController.text.trim());
  }

  void _openMartyrDetail(Martyr martyr) {
    print("📌 _openMartyrDetail called for ${martyr.firstName} ${martyr.lastName}");
    final shell = AppShell.of(context);
    if (shell != null) {
      shell.openEmbeddedPage(
        MartyrDetailPage(martyrId: martyr.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("📌 _MartyrListPageState.build called, widget.pageTitle=${widget.pageTitle}");
    return Column(
      children: [
        // فیلد جستجو
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'جستجوی شهید...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _performSearch,
                child: const Text('جستجو'),
              ),
            ],
          ),
        ),
        // لیست شهدا
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _martyrs.isEmpty
                  ? const Center(child: Text('هیچ شهیدی یافت نشد'))
                  : ListView.builder(
                      itemCount: _martyrs.length,
                      itemBuilder: (_, i) {
                        final m = _martyrs[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: (m.photo != null && m.photo!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      m.photo!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, size: 40),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 40),
                            title: Text('${m.firstName} ${m.lastName}'),
                            subtitle: Text([ 
                              if (m.martyrPlace?.isNotEmpty ?? false)
                                m.martyrPlace,
                              if (m.martyrDate?.isNotEmpty ?? false)
                                m.martyrDate,
                            ].whereType<String>().join(' - ')),
                            onTap: () => _openMartyrDetail(m),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
