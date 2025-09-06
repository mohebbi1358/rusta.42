import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../services/api_client.dart';
import '../main/app_shell.dart';
import 'martyr_memory_page.dart'; // فرض: صفحه‌ی خاطرات موجود است و پارامتر embedded ندارد.

class MartyrDetailPage extends StatefulWidget implements PageWithTitle {
  final int martyrId;

  // برای عنوان پویا: ابتدا "مشخصات شهید"، بعد از لود نام شهید
  final ValueNotifier<String> _titleNotifier = ValueNotifier<String>("مشخصات شهید");

  MartyrDetailPage({super.key, required this.martyrId});

  @override
  String get pageTitle => _titleNotifier.value;

  @override
  State<MartyrDetailPage> createState() => _MartyrDetailPageState();
}

class _MartyrDetailPageState extends State<MartyrDetailPage> {
  Map<String, dynamic>? martyr;
  List<dynamic> latestMemories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchMartyr(),
      _fetchLatestMemories(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchMartyr() async {
    try {
      final res = await Dio().get(
        "${ApiClient.baseUrl}/api/martyrs/${widget.martyrId}/",
      );
      if (res.statusCode == 200) {
        martyr = res.data as Map<String, dynamic>;
        // عنوان: نام + نام‌خانوادگی (اگر موجود بود)
        final first = (martyr?['first_name'] ?? "").toString().trim();
        final last  = (martyr?['last_name']  ?? "").toString().trim();
        final fullName = [first, last].where((e) => e.isNotEmpty).join(' ');
        if (fullName.isNotEmpty) {
          widget._titleNotifier.value = fullName;
          // به AppShell بگو تیتر را رفرش کند
          AppShell.of(context)?.refreshTitle();
        }
      }
    } catch (e) {
      // می‌تونید Snackbar هم بزنید
      debugPrint("❌ خطا در دریافت مشخصات شهید: $e");
    }
  }

  Future<void> _fetchLatestMemories() async {
    try {
      // الگوی رایج برای ویوی Latest شما:
      // /api/martyrs/<id>/memories/latest/
      final res = await Dio().get(
        "${ApiClient.baseUrl}/api/martyrs/${widget.martyrId}/memories/latest/",
      );
      if (res.statusCode == 200 && mounted) {
        latestMemories = (res.data as List?) ?? [];
      }
    } catch (e) {
      debugPrint("❌ خطا در دریافت 3 دل‌نوشته آخر: $e");
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return "-";
    try {
      final g = DateTime.parse(iso);
      final j = Gregorian(g.year, g.month, g.day).toJalali();
      return "${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return iso;
    }
  }

  String? _bestImageUrl(Map<String, dynamic> m) {
    // تلاش برای پیدا کردن URL عکس: photo_url | main_image_url | photo (relative)
    final photoUrl = (m['photo_url'] ?? m['main_image_url'] ?? m['image_url'])?.toString();
    if (photoUrl != null && photoUrl.isNotEmpty) return photoUrl;

    final photo = (m['photo'] ?? '').toString();
    if (photo.isNotEmpty) {
      // اگر نسبی است با baseUrl ترکیب کن
      if (photo.startsWith('http')) return photo;
      return "${ApiClient.baseUrl}$photo";
    }
    return null;
    // اگر هیچ چیز نبود: null → آیکن پیش‌فرض
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.toString().trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (martyr == null) {
      return const Center(child: Text("اطلاعاتی یافت نشد"));
    }

    final m = martyr!;
    final imageUrl = _bestImageUrl(m);
    final fullName = [
      (m['first_name'] ?? "").toString().trim(),
      (m['last_name'] ?? "").toString().trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // عکس
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60)),

            const SizedBox(height: 12),
            // نام
            Text(fullName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),
            // اطلاعات
            _infoRow("نام پدر", m['father_name']?.toString()),
            _infoRow("محل تولد", m['birth_place']?.toString()),
            _infoRow("تاریخ تولد", _formatDate(m['birth_date']?.toString())),
            _infoRow("آخرین عملیات", m['last_operation']?.toString()),
            _infoRow("منطقه شهادت", m['martyr_region']?.toString()),
            _infoRow("محل شهادت", m['martyr_place']?.toString()),
            _infoRow("تاریخ شهادت", _formatDate(m['martyr_date']?.toString())),
            _infoRow("محل دفن", m['grave_place']?.toString()),

            const SizedBox(height: 20),

            // دل‌نوشته‌های اخیر
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "دل‌نوشته‌های اخیر",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (latestMemories.isEmpty)
              const Align(
                alignment: Alignment.centerRight,
                child: Text("هیچ دل‌نوشته‌ای ثبت نشده است"),
              )
            else
              ...latestMemories.map((n) {
                final user = (n['user_full_name'] ?? "ناشناس").toString();
                final text = (n['text'] ?? "").toString();
                final createdAt = (n['created_at'] ?? "").toString();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(
                      user,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (text.isNotEmpty) Text(text),
                        if (createdAt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              createdAt,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),

            // رفتن به صفحهٔ همهٔ دل‌نوشته‌ها (embedded)
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text("مشاهده همه دل‌نوشته‌ها"),
                onPressed: () {
                  AppShell.of(context)
                      ?.openEmbeddedPage(MartyrMemoryPage(martyrId: widget.martyrId));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
