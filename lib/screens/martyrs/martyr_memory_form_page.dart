import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';

class MartyrMemoryFormPage extends StatefulWidget {
  final Map<String, dynamic>? memory; // اگر ویرایش هست
  final int? martyrId; // برای ساخت دل‌نوشته جدید

  const MartyrMemoryFormPage({super.key, this.memory, this.martyrId});

  @override
  State<MartyrMemoryFormPage> createState() => _MartyrMemoryFormPageState();
}

class _MartyrMemoryFormPageState extends State<MartyrMemoryFormPage> {
  final TextEditingController _textController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.memory != null) {
      _textController.text = widget.memory!['text'] ?? '';
    }
  }

  Future<void> _submitMemory() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final dio = Dio();

      if (widget.memory != null) {
        // ویرایش دل‌نوشته
        final id = widget.memory!['id'];
        await dio.put(
          "${ApiClient.baseUrl}/api/memories/$id/edit/",
          data: {"text": _textController.text.trim()},
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
      } else if (widget.martyrId != null) {
        // ایجاد دل‌نوشته جدید
        await dio.post(
          "${ApiClient.baseUrl}/api/martyrs/${widget.martyrId}/memories/",
          data: {"text": _textController.text.trim()},
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
      }

      Navigator.pop(context, true); // ریفرش صفحه قبل
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطا در ذخیره دل‌نوشته")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.memory != null
              ? "ویرایش دل‌نوشته"
              : "دل‌نوشته جدید")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: null,
              decoration:
                  const InputDecoration(labelText: "متن دل‌نوشته", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submitMemory,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("ذخیره"),
            ),
          ],
        ),
      ),
    );
  }
}
