// lib/screens/news/news_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../models/news.dart';

class NewsDetailPage extends StatelessWidget {
  final News news;
  final VoidCallback? onBack;
  final bool embedded; // اگر true → فقط محتوای صفحه (بدون Scaffold و AppBar)

  const NewsDetailPage({
    super.key,
    required this.news,
    this.onBack,
    this.embedded = false,
  });

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
    // محتوای صفحه (بدون Scaffold)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // تصویر شاخص به صورت بندانگشتی مربع بالا (قابل کلیک)
          if (news.mainImage.isNotEmpty)
            GestureDetector(
              onTap: () => _openImagePopup(context, news.mainImage),
              child: Align(
                alignment: Alignment.centerRight, // راست‌چین
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: news.mainImage,
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

          // عنوان
          Text(
            news.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          // دسته و تاریخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(news.categoryName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(_formatJalali(news.createdAt), style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          // خلاصه (اگر موجود)
          if (news.summary.isNotEmpty)
            Text(news.summary, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
          if (news.summary.isNotEmpty) const SizedBox(height: 12),

          // متن کامل
          Text(news.body, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 12),

          // لینک‌ها
          if (news.links.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: news.links.map((link) {
                final title = link['title'] ?? link['url'] ?? '';
                final url = link['url'] ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => _openLink(context, url),
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 16),
                    ),
                  ),
                );
              }).toList(),
            ),

          // تصاویر اضافی بندانگشتی
          if (news.extraImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: news.extraImages.map((img) {
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
    if (embedded) {
      // فقط محتوای داخلی (بدون Scaffold) — برای نمایش داخل AppShell
      return _buildContent(context);
    }

    // حالت مستقل: Scaffold و AppBar خودش را دارد
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جزئیات خبر'),
          leading: onBack != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack) : null,
        ),
        body: _buildContent(context),
      ),
    );
  }
}
