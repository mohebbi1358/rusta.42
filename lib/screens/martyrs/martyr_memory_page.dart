import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';

class MartyrMemoryPage extends StatefulWidget {
  final int martyrId;

  const MartyrMemoryPage({super.key, required this.martyrId});

  @override
  State<MartyrMemoryPage> createState() => _MartyrMemoryPageState();
}

class _MartyrMemoryPageState extends State<MartyrMemoryPage> {
  final TextEditingController _textController = TextEditingController();
  bool _loading = true;
  List<dynamic> _memories = [];

  String? _currentUserPhone;
  bool _is_admin = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserInfo();
    await _fetchMemories();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserPhone = prefs.getString('phone');
    _is_admin = prefs.getBool('is_admin') ?? false;

    print("🔹 Loaded user info: phone=$_currentUserPhone, is_admin=$_is_admin");
  }

  Future<void> _fetchMemories() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final dio = Dio();
      final res = await dio.get(
        "${ApiClient.baseUrl}/api/martyrs/${widget.martyrId}/memories/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode == 200) {
        setState(() => _memories = res.data);
      }
    } catch (e) {
      print("❌ Error fetching memories: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطا در دریافت دل‌نوشته‌ها")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendMemory() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final dio = Dio();
      final res = await dio.post(
        "${ApiClient.baseUrl}/api/martyrs/${widget.martyrId}/memories/",
        data: {"text": text},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        _textController.clear();
        await _fetchMemories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("دل‌نوشته با موفقیت ارسال شد")),
        );
      }
    } catch (e) {
      print("❌ Error sending memory: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطا در ارسال دل‌نوشته")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editMemory(int memoryId, String oldText) async {
    final controller = TextEditingController(text: oldText);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ویرایش دل‌نوشته"),
        content: TextField(controller: controller, maxLines: 5),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('access_token');

              final dio = Dio();
              await dio.put(
                "${ApiClient.baseUrl}/api/memories/$memoryId/edit/", // ✅ URL اصلاح شد
                data: {"text": controller.text},
                options: Options(headers: {"Authorization": "Bearer $token"}),
              );
              Navigator.pop(ctx);
              await _fetchMemories();
            },
            child: const Text("ذخیره"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMemory(int memoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final dio = Dio();
      await dio.delete(
        "${ApiClient.baseUrl}/api/memories/$memoryId/delete/", // ✅ URL اصلاح شد
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      await _fetchMemories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("دل‌نوشته حذف شد")),
      );
    } catch (e) {
      print("❌ Error deleting memory: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطا در حذف دل‌نوشته")),
      );
    }
  }

  bool _canEdit(Map<String, dynamic> memory) {
    final memoryId = memory['id'];
    final memoryPhone = memory['user_phone'] ?? '';
    final createdAt = DateTime.parse(memory['created_at']).toLocal();
    final editLimit = createdAt.add(const Duration(hours: 2));
    final now = DateTime.now();

    if (_is_admin) {
      print("🟢 Admin can edit memory $memoryId without restriction");
      return true;
    }

    if (memoryPhone != _currentUserPhone) {
      print("🔴 User cannot edit memory $memoryId: not the owner (memoryPhone=$memoryPhone, currentUser=$_currentUserPhone)");
      return false;
    }

    final canEdit = now.isBefore(editLimit);
    print("📝 Edit check for memory $memoryId: createdAt=$createdAt, editLimit=$editLimit, now=$now, canEdit=$canEdit");
    return canEdit;
  }

  bool _canDelete(Map<String, dynamic> memory) {
    final memoryId = memory['id'];
    final memoryPhone = memory['user_phone'] ?? '';
    final createdAt = DateTime.parse(memory['created_at']).toLocal();
    final deleteLimit = createdAt.add(const Duration(minutes: 2));
    final now = DateTime.now();

    if (_is_admin) {
      print("🟢 Admin can delete memory $memoryId without restriction");
      return true;
    }

    if (memoryPhone != _currentUserPhone) {
      print("🔴 User cannot delete memory $memoryId: not the owner (memoryPhone=$memoryPhone, currentUser=$_currentUserPhone)");
      return false;
    }

    final canDelete = now.isBefore(deleteLimit);
    print("📝 Delete check for memory $memoryId: createdAt=$createdAt, deleteLimit=$deleteLimit, now=$now, canDelete=$canDelete");
    return canDelete;
  }

  bool _canModify(Map<String, dynamic> memory) => _canEdit(memory) || _canDelete(memory);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _memories.isEmpty
                  ? const Center(child: Text("هنوز دل‌نوشته‌ای وجود ندارد"))
                  : ListView.builder(
                      itemCount: _memories.length,
                      itemBuilder: (ctx, i) {
                        final memory = _memories[i];
                        final canEdit = _canEdit(memory);
                        final canDelete = _canDelete(memory);
                        final canModify = _canModify(memory);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            title: Text(
                              (memory['user_full_name']?.toString().trim().isNotEmpty ?? false)
                                  ? memory['user_full_name']
                                  : "ناشناس",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(memory['text'] ?? ""),
                            trailing: canModify
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit' && canEdit) {
                                        _editMemory(memory['id'], memory['text']);
                                      } else if (value == 'delete' && canDelete) {
                                        _deleteMemory(memory['id']);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      if (canEdit)
                                        const PopupMenuItem(value: 'edit', child: Text("ویرایش")),
                                      if (canDelete)
                                        const PopupMenuItem(value: 'delete', child: Text("حذف")),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "دل‌نوشته خود را بنویسید...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMemory,
                child: const Text("ارسال"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
