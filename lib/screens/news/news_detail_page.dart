import 'package:hamyar/screens/news/edit_news_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/news.dart';
import '../../services/api_client.dart';

class NewsDetailPage extends StatefulWidget {
  final News news;
  final VoidCallback? onBack;
  final bool embedded;

  const NewsDetailPage({
    super.key,
    required this.news,
    this.onBack,
    this.embedded = false,
  });

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late News _news;

  // 🔹 وضعیت ادمین از SharedPreferences
  bool _is_admin = false;

  @override
  void initState() {
    super.initState();
    _news = widget.news;
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _is_admin = prefs.getBool('is_admin') ?? false;
    });
    print("🔹 Loaded admin status: $_is_admin");
  }

  bool get canEdit {
    final now = DateTime.now();
    final editLimit = _news.createdAt.add(const Duration(hours: 2));

    if (_is_admin) {
      print("🟢 Admin can edit news ${_news.id} without restriction");
      return true;
    }

    if (!_news.isOwner) {
      print("🔴 User cannot edit news ${_news.id}: not the owner");
      return false;
    }

    final canEdit = now.isBefore(editLimit);
    print("📝 Edit check for news ${_news.id}: createdAt=${_news.createdAt}, editLimit=$editLimit, now=$now, canEdit=$canEdit");
    return canEdit;
  }

  bool get canDelete {
    final now = DateTime.now();
    final deleteLimit = _news.createdAt.add(const Duration(minutes: 2));

    if (_is_admin) {
      print("🟢 Admin can delete news ${_news.id} without restriction");
      return true;
    }

    if (!_news.isOwner) {
      print("🔴 User cannot delete news ${_news.id}: not the owner");
      return false;
    }

    final canDelete = now.isBefore(deleteLimit);
    print("📝 Delete check for news ${_news.id}: createdAt=${_news.createdAt}, deleteLimit=$deleteLimit, now=$now, canDelete=$canDelete");
    return canDelete;
  }

  void _updateNews(News updated) {
    setState(() {
      _news = updated;
    });
  }

  void _editNews(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditNewsPage(
          news: _news,
          onUpdated: _updateNews,
        ),
      ),
    );
  }

  Future<void> _deleteNews(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("حذف خبر"),
        content: const Text("آیا مطمئن هستید؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("انصراف")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف")),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final dio = Dio()..options.headers['Authorization'] = 'Bearer $token';
      await dio.delete('${ApiClient.baseUrl}/api/news/${_news.id}/delete/');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خبر با موفقیت حذف شد')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف خبر: $e')),
        );
      }
    }
  }

  void _openImagePopup(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لینک نامعتبر است')));
      return;
    }
    final clean = url.trim().startsWith('http') ? url.trim() : 'https://${url.trim()}';
    final uri = Uri.parse(clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('امکان باز کردن لینک وجود ندارد')));
    }
  }

  String _formatJalali(DateTime date) {
    final j = Jalali.fromDateTime(date);
    return "${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}";
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_news.mainImage.isNotEmpty)
            GestureDetector(
              onTap: () => _openImagePopup(context, _news.mainImage),
              child: Align(
                alignment: Alignment.centerRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _news.mainImage,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      width: 120,
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(_news.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_news.categoryName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(_formatJalali(_news.createdAt), style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          if (_news.summary.isNotEmpty)
            Text(_news.summary, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
          if (_news.summary.isNotEmpty) const SizedBox(height: 12),
          Text(_news.body, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 12),
          if (_news.links.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _news.links.map((link) {
                final title = link['title'] ?? link['url'] ?? '';
                final url = link['url'] ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => _openLink(context, url),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          if (_news.extraImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _news.extraImages.map((img) {
                if (img.isEmpty) return const SizedBox();
                return GestureDetector(
                  onTap: () => _openImagePopup(context, img),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: img,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            _buildContent(context),
            if (canEdit || canDelete)
              Positioned(
                top: 16,
                left: 16,
                child: Row(
                  children: [
                    if (canEdit)
                      FloatingActionButton.small(
                        heroTag: "edit_btn",
                        backgroundColor: Colors.blue,
                        onPressed: () => _editNews(context),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    const SizedBox(width: 8),
                    if (canDelete)
                      FloatingActionButton.small(
                        heroTag: "delete_btn",
                        backgroundColor: Colors.red,
                        onPressed: () => _deleteNews(context),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
