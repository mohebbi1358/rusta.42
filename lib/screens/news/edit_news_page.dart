import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/news.dart';
import '../../services/api_client.dart';

class EditNewsPage extends StatefulWidget {
  final News news;
  final void Function(News)? onUpdated; // callback بعد از ویرایش

  const EditNewsPage({super.key, required this.news, this.onUpdated});

  @override
  State<EditNewsPage> createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _summaryController.text = widget.news.summary;
    _contentController.text = widget.news.body;
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) throw Exception("توکن موجود نیست");

      final dio = Dio();

      final response = await dio.patch(
        "${ApiClient.baseUrl}/api/news/${widget.news.id}/edit/",
        data: {
          "summary": _summaryController.text.trim(),
          "body": _contentController.text.trim(),
        },
        options: Options(headers: {"Authorization": "Bearer $accessToken"}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("خبر با موفقیت ویرایش شد")),
        );

        // ایجاد نسخه‌ی جدید از news با مقادیر جدید
        final updatedNews = widget.news.copyWith(
          summary: _summaryController.text.trim(),
          body: _contentController.text.trim(),
        );

        // فراخوانی callback اگر موجود باشد
        if (widget.onUpdated != null) {
          widget.onUpdated!(updatedNews);
        }

        Navigator.pop(context); // فقط صفحه ادیت بسته می‌شود، چرخه loop ایجاد نمی‌شود
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا در ویرایش: ${response.statusCode}")),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در ارتباط با سرور: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ویرایش خبر")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // عنوان (قفل شده)
                    TextFormField(
                      initialValue: widget.news.title,
                      enabled: false,
                      decoration: const InputDecoration(labelText: "عنوان"),
                    ),
                    const SizedBox(height: 10),

                    // دسته‌بندی (قفل شده)
                    TextFormField(
                      initialValue: widget.news.categoryName ?? "",
                      enabled: false,
                      decoration:
                          const InputDecoration(labelText: "دسته‌بندی"),
                    ),
                    const SizedBox(height: 10),

                    // خلاصه خبر (قابل ویرایش)
                    TextFormField(
                      controller: _summaryController,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: "خلاصه خبر"),
                      validator: (v) => v == null || v.isEmpty
                          ? "خلاصه خبر الزامی است"
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // متن خبر (قابل ویرایش)
                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration:
                          const InputDecoration(labelText: "متن خبر"),
                      validator: (v) => v == null || v.isEmpty
                          ? "متن خبر الزامی است"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _loading ? null : _submitEdit,
                      child: const Text("ثبت تغییرات"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
