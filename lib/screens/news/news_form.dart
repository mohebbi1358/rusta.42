import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateNewsPage extends StatefulWidget {
  const CreateNewsPage({super.key});

  @override
  _CreateNewsPageState createState() => _CreateNewsPageState();
}

class _CreateNewsPageState extends State<CreateNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();

  File? _mainImage;
  Uint8List? _mainImageWeb;
  final List<File> _extraImages = [];
  final List<Uint8List> _extraImagesWeb = [];

  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  // دسته‌بندی
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _allowedCategories = [];

  // محدودیت ارسال امروز
  bool _canSubmitToday = true;

  @override
  void initState() {
    super.initState();
    _fetchAllowedCategories();
  }

  Future<void> _fetchAllowedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) return;

      final dio = Dio();
      final response = await dio.get(
        'http://localhost:8000/api/allowed-categories/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _allowedCategories = List<Map<String, dynamic>>.from(response.data);
          if (_allowedCategories.isNotEmpty) {
            _selectedCategoryId = _allowedCategories.first['id'];
            _checkTodayNews(); // بررسی محدودیت برای دسته پیش‌فرض
          }
        });
      }
    } catch (e) {
      print('خطا در دریافت دسته‌بندی‌ها: $e');
    }
  }

  Future<void> _checkTodayNews() async {
    if (_selectedCategoryId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) return;

      final dio = Dio();
      final response = await dio.get(
        'http://localhost:8000/api/news/?category=$_selectedCategoryId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final today = DateTime.now();
        final newsList = List<Map<String, dynamic>>.from(response.data);
        setState(() {
          _canSubmitToday = !newsList.any((n) {
            final createdAt = DateTime.parse(n['created_at']);
            return createdAt.year == today.year &&
                   createdAt.month == today.month &&
                   createdAt.day == today.day;
          });
        });
      }
    } catch (e) {
      print('خطا در بررسی محدودیت ارسال: $e');
    }
  }

  Future<void> _pickMainImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _mainImageWeb = bytes);
      } else {
        setState(() => _mainImage = File(picked.path));
      }
    }
  }

  Future<void> _pickExtraImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _extraImagesWeb.add(bytes));
      } else {
        final file = File(picked.path);
        if (!_extraImages.any((f) => f.path == file.path)) {
          setState(() => _extraImages.add(file));
        }
      }
    }
  }

  Future<void> _submitNews() async {
    if (!_formKey.currentState!.validate()) return;

    if ((!kIsWeb && _mainImage == null) || (kIsWeb && _mainImageWeb == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا عکس اصلی را انتخاب کنید.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = Dio();

      List<MultipartFile> extraImagesFiles = [];
      if (kIsWeb) {
        extraImagesFiles = _extraImagesWeb
            .map((b) => MultipartFile.fromBytes(b, filename: 'extra.png'))
            .toList();
      } else {
        extraImagesFiles = await Future.wait(
            _extraImages.map((f) => MultipartFile.fromFile(f.path)));
      }

      final formData = FormData.fromMap({
        'title': _titleController.text.trim(),
        'summary': _summaryController.text.trim(),
        'body': _contentController.text.trim(),
        'category': _selectedCategoryId,
        'main_image': kIsWeb
            ? MultipartFile.fromBytes(_mainImageWeb!, filename: 'main_image.png')
            : await MultipartFile.fromFile(_mainImage!.path),
        'images': extraImagesFiles,
      });

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) throw Exception('توکن موجود نیست');

      final response = await dio.post(
        'http://localhost:8000/api/news/create/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خبر با موفقیت ارسال شد!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'خطا در ارسال خبر: ${response.statusCode} ${response.statusMessage}')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ارتباط با سرور: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ارسال خبر')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'عنوان'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'عنوان الزامی است' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(labelText: 'خلاصه خبر'),
                      maxLines: 2,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'خلاصه خبر الزامی است' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: 'متن خبر'),
                      maxLines: 5,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'متن خبر الزامی است' : null,
                    ),
                    const SizedBox(height: 10),
                    _allowedCategories.isNotEmpty
                        ? DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            decoration:
                                const InputDecoration(labelText: 'دسته‌بندی'),
                            items: _allowedCategories
                                .map((c) => DropdownMenuItem<int>(
                                      value: c['id'],
                                      child: Text(c['name']),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedCategoryId = val);
                              _checkTodayNews(); // بررسی محدودیت برای دسته انتخابی
                            },
                            validator: (v) => v == null
                                ? 'انتخاب دسته‌بندی الزامی است'
                                : null,
                          )
                        : const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 10),
                    (_mainImage != null && !kIsWeb)
                        ? Image.file(_mainImage!, width: 100, height: 100)
                        : (_mainImageWeb != null && kIsWeb)
                            ? Image.memory(_mainImageWeb!, width: 100, height: 100)
                            : const SizedBox(),
                    ElevatedButton(
                      onPressed: _pickMainImage,
                      child: const Text('انتخاب عکس اصلی'),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (!kIsWeb)
                          for (int i = 0; i < _extraImages.length; i++)
                            Stack(
                              children: [
                                Image.file(_extraImages[i],
                                    width: 100, height: 100),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _extraImages.removeAt(i)),
                                    child: const Icon(Icons.close, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                        if (kIsWeb)
                          for (int i = 0; i < _extraImagesWeb.length; i++)
                            Stack(
                              children: [
                                Image.memory(_extraImagesWeb[i],
                                    width: 100, height: 100),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    
                                    onTap: () =>
                                        setState(() => _extraImagesWeb.removeAt(i)),
                                    child: const Icon(Icons.close, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                        ElevatedButton(
                          onPressed: _pickExtraImage,
                          child: const Text('افزودن عکس اضافی'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _canSubmitToday && !_loading ? _submitNews : null,
                      child: Text(
                        _canSubmitToday
                            ? 'ارسال خبر'
                            : 'امروز قبلاً خبری ارسال شده',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
