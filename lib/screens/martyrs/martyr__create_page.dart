import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_client.dart';

class CreateMartyrPage extends StatefulWidget {
  const CreateMartyrPage({super.key});

  @override
  State<CreateMartyrPage> createState() => _CreateMartyrPageState();
}

class _CreateMartyrPageState extends State<CreateMartyrPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _mainImage;
  Uint8List? _mainImageWeb;
  final List<File> _extraImages = [];
  final List<Uint8List> _extraImagesWeb = [];
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;

  Jalali? _birthDate;
  Jalali? _martyrdomDate;

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

  Future<void> _pickDate(bool isBirth) async {
    final now = Jalali.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.toGregorian().toDateTime(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final g = Gregorian(picked.year, picked.month, picked.day);
      final j = g.toJalali();
      setState(() {
        if (isBirth) {
          _birthDate = j;
        } else {
          _martyrdomDate = j;
        }
      });
    }
  }

  Future<void> _submitMartyr() async {
    if (!_formKey.currentState!.validate()) return;
    if ((!kIsWeb && _mainImage == null) || (kIsWeb && _mainImageWeb == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا عکس اصلی را انتخاب کنید.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("توکن موجود نیست");

      final dio = Dio();

      final mainImageFile = kIsWeb
          ? MultipartFile.fromBytes(_mainImageWeb!, filename: 'main.png')
          : await MultipartFile.fromFile(_mainImage!.path);

      List<MultipartFile> extraFiles = [];
      if (kIsWeb) {
        extraFiles = _extraImagesWeb
            .map((b) => MultipartFile.fromBytes(b, filename: 'extra.png'))
            .toList();
      } else {
        extraFiles = await Future.wait(
          _extraImages.map((f) => MultipartFile.fromFile(f.path)),
        );
      }

      final formData = FormData();
      formData.fields.addAll([
        MapEntry('name', _nameController.text.trim()),
        MapEntry('bio', _bioController.text.trim()),
        if (_birthDate != null)
          MapEntry('birth_date',
              _birthDate!.toGregorian().toDateTime().toIso8601String()),
        if (_martyrdomDate != null)
          MapEntry('martyrdom_date',
              _martyrdomDate!.toGregorian().toDateTime().toIso8601String()),
      ]);

      formData.files.add(MapEntry('main_image', mainImageFile));

      for (var img in extraFiles) {
        formData.files.add(MapEntry('images', img));
      }

      final response = await dio.post(
        '${ApiClient.baseUrl}/api/martyrs/create/',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شهید با موفقیت ثبت شد')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      print("❌ خطا: $e");
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
      appBar: AppBar(title: const Text("ایجاد شهید")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "نام شهید"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "نام الزامی است" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(labelText: "زندگینامه"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "زندگینامه الزامی است" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_birthDate != null
                            ? "تولد: ${_birthDate!.formatCompactDate()}"
                            : "تاریخ تولد انتخاب نشده"),
                        ElevatedButton(
                          onPressed: () => _pickDate(true),
                          child: const Text("انتخاب تولد"),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_martyrdomDate != null
                            ? "شهادت: ${_martyrdomDate!.formatCompactDate()}"
                            : "تاریخ شهادت انتخاب نشده"),
                        ElevatedButton(
                          onPressed: () => _pickDate(false),
                          child: const Text("انتخاب شهادت"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    (_mainImage != null && !kIsWeb)
                        ? Image.file(_mainImage!, width: 100, height: 100)
                        : (_mainImageWeb != null && kIsWeb)
                            ? Image.memory(_mainImageWeb!,
                                width: 100, height: 100)
                            : const SizedBox(),
                    ElevatedButton(
                      onPressed: _pickMainImage,
                      child: const Text("انتخاب عکس اصلی"),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (int i = 0; i < _extraImages.length; i++)
                          Image.file(_extraImages[i], width: 80, height: 80),
                        for (int i = 0; i < _extraImagesWeb.length; i++)
                          Image.memory(_extraImagesWeb[i],
                              width: 80, height: 80),
                        ElevatedButton(
                          onPressed: _pickExtraImage,
                          child: const Text("افزودن عکس اضافی"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitMartyr,
                      child: const Text("ثبت شهید"),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
