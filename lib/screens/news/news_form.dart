import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/news.dart';
import '../../services/api_client.dart';

class CreateNewsPage extends StatefulWidget {
  final News? existingNews;

  const CreateNewsPage({super.key, this.existingNews});

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
  bool _loadingCheck = false; // بررسی محدودیت

  int? _selectedCategoryId;
  List<Map<String, dynamic>> _allowedCategories = [];

  bool _canSubmitToday = true;
  String _dailyLimitMessage = '';

  List<Map<String, String>> _links = [];

  @override
  void initState() {
    super.initState();
    _fetchAllowedCategories();
    if (widget.existingNews != null) {
      _loadExistingNews(widget.existingNews!);
    }
  }

  void _loadExistingNews(News news) {
    _titleController.text = news.title;
    _summaryController.text = news.summary;
    _contentController.text = news.body;
    _selectedCategoryId = news.categoryId;
    _links = List<Map<String, String>>.from(news.links);
  }

  Future<void> _fetchAllowedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) return;

      final dio = Dio();
      final response = await dio.get(
        '${ApiClient.baseUrl}/api/allowed-categories/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _allowedCategories = List<Map<String, dynamic>>.from(response.data);
          if (_allowedCategories.isNotEmpty) {
            _selectedCategoryId ??= _allowedCategories.first['id'];
            _checkTodayNews();
          }
        });
      }
    } catch (e) {
      print('خطا در دریافت دسته‌بندی‌ها: $e');
    }
  }

  Future<void> _checkTodayNews() async {
    if (_selectedCategoryId == null) return;

    setState(() {
      _loadingCheck = true;
      _dailyLimitMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) return;

      final dio = Dio();
      final response = await dio.get(
        '${ApiClient.baseUrl}/api/news/check-daily-limit/',
        queryParameters: {'category_id': _selectedCategoryId},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _canSubmitToday = data['can_submit'] ?? true;
          _dailyLimitMessage = data['message'] ?? '';
        });
      }
    } catch (e) {
      print('خطا در بررسی محدودیت ارسال: $e');
      setState(() {
        _canSubmitToday = false;
        _dailyLimitMessage = 'خطا در بررسی محدودیت ارسال';
      });
    } finally {
      setState(() => _loadingCheck = false);
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

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا دسته‌بندی را انتخاب کنید.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) throw Exception('توکن موجود نیست');

      final dio = Dio();

      // فایل اصلی
      final mainImageFile = kIsWeb
          ? MultipartFile.fromBytes(_mainImageWeb!, filename: 'main_image.png')
          : await MultipartFile.fromFile(_mainImage!.path);

      // تصاویر اضافی
      List<MultipartFile> extraImagesFiles = [];
      if (kIsWeb) {
        extraImagesFiles = _extraImagesWeb
            .map((b) => MultipartFile.fromBytes(b, filename: 'extra.png'))
            .toList();
      } else {
        extraImagesFiles = await Future.wait(
          _extraImages.map((f) => MultipartFile.fromFile(f.path)),
        );
      }

      final formData = FormData();

      // فیلدهای اصلی
      formData.fields.addAll([
        MapEntry('title', _titleController.text.trim()),
        MapEntry('summary', _summaryController.text.trim()),
        MapEntry('body', _contentController.text.trim()),
        MapEntry('category', _selectedCategoryId.toString()),
      ]);

      // فایل اصلی
      formData.files.add(MapEntry('main_image', mainImageFile));

      // تصاویر اضافی
      for (var img in extraImagesFiles) {
        formData.files.add(MapEntry('images', img));
      }

      // لینک‌ها به شکل ایندکسی (سازگار با DRF)
      final linksData = _links
          .where((link) => link['title']!.isNotEmpty && link['url']!.isNotEmpty)
          .toList();

      for (int i = 0; i < linksData.length; i++) {
        formData.fields.add(MapEntry('links[$i][title]', linksData[i]['title']!));
        formData.fields.add(MapEntry('links[$i][url]', linksData[i]['url']!));
      }


      final response = await dio.post(
        '${ApiClient.baseUrl}/api/news/create/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خبر با موفقیت ارسال شد!')),
        );
        Navigator.pushReplacementNamed(context, '/news-list');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'خطا در ارسال خبر: ${response.statusCode} ${response.statusMessage}'),
          ),
        );
      }
    } catch (e) {
      print("❌ خطا: $e");
      if (e is DioException) {
        print("❌ پاسخ خطا: ${e.response?.data}");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ارتباط با سرور: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }



  Widget _buildLinksSection() {
    return Column(
      children: [
        for (int i = 0; i < _links.length; i++)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _links[i]['title'],
                  decoration: const InputDecoration(labelText: 'عنوان لینک'),
                  onChanged: (val) => _links[i]['title'] = val,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _links[i]['url'],
                  decoration: const InputDecoration(labelText: 'آدرس لینک'),
                  onChanged: (val) => _links[i]['url'] = val,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _links.removeAt(i);
                  });
                },
              ),
            ],
          ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _links.add({'title': '', 'url': ''});
            });
          },
          child: const Text('افزودن لینک'),
        ),
      ],
    );
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
                    // عنوان
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'عنوان'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'عنوان الزامی است' : null,
                    ),
                    const SizedBox(height: 10),

                    // خلاصه خبر
                    TextFormField(
                      controller: _summaryController,
                      decoration:
                          const InputDecoration(labelText: 'خلاصه خبر'),
                      maxLines: 2,
                      validator: (v) => v == null || v.isEmpty
                          ? 'خلاصه خبر الزامی است'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // متن خبر
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: 'متن خبر'),
                      maxLines: 5,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'متن خبر الزامی است' : null,
                    ),
                    const SizedBox(height: 10),




                    // دسته‌بندی
                    _allowedCategories.isNotEmpty
                      ? Card(
                          color: Colors.white, // رنگ مشخص و واقعی
                          elevation: 2,        // سایه برای تأکید بر Material
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'دسته‌بندی',
                                border: OutlineInputBorder(),
                              ),
                              items: _allowedCategories
                                  .map((c) => DropdownMenuItem<int>(
                                        value: c['id'],
                                        child: Text(c['name']),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedCategoryId = val);
                                _checkTodayNews();
                              },
                              validator: (v) =>
                                  v == null ? 'انتخاب دسته‌بندی الزامی است' : null,
                            ),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),


                    if (!_canSubmitToday && _dailyLimitMessage.isNotEmpty)
                      Text(
                        _dailyLimitMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 16),

                    // عکس اصلی
                    (_mainImage != null && !kIsWeb)
                        ? Image.file(_mainImage!, width: 100, height: 100)
                        : (_mainImageWeb != null && kIsWeb)
                            ? Image.memory(_mainImageWeb!,
                                width: 100, height: 100)
                            : const SizedBox(),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickMainImage,
                      child: const Text('انتخاب عکس اصلی'),
                    ),
                    const SizedBox(height: 24),

                    // تصاویر اضافی
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
                                    child: const Icon(Icons.close,
                                        color: Colors.red),
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
                                    onTap: () => setState(
                                        () => _extraImagesWeb.removeAt(i)),
                                    child: const Icon(Icons.close,
                                        color: Colors.red),
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
                    const SizedBox(height: 10),

                    // لینک‌ها
                    _buildLinksSection(),
                    const SizedBox(height: 20),

                    // دکمه ارسال
                    ElevatedButton(
                      onPressed: !_loading && !_loadingCheck && _canSubmitToday
                          ? _submitNews
                          : null,
                      child: Text(
                        _canSubmitToday ? 'ارسال خبر' : 'محدودیت ارسال خبر',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
