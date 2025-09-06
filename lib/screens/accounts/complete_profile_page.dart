import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hamyar/services/auth_service.dart';
import 'package:hamyar/services/number_converter.dart';
import 'package:provider/provider.dart';
import 'package:hamyar/providers/user_provider.dart';
import 'package:hamyar/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CompleteProfilePage extends StatefulWidget {
  final String phone;

  const CompleteProfilePage({super.key, required this.phone});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String _errorMessage = '';

  String? _selectedGender = 'M';
  File? _profileImage;
  Uint8List? _profileImageBytes; // برای وب
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await AuthService.getProfile();
      print("Loaded profile: $profile");

      _firstNameController.text = profile['first_name'] ?? '';
      _lastNameController.text = profile['last_name'] ?? '';
      _fatherNameController.text = profile['father_name'] ?? '';
      _selectedGender = profile['gender'] ?? 'M';

      final imageUrl = profile['image'];
      if (imageUrl != null && kIsWeb) {
        try {
          final url = Uri.parse("${AuthService.baseUrl}$imageUrl");
          final response = await http.get(url);
          if (response.statusCode == 200) {
            setState(() {
              _profileImageBytes = response.bodyBytes;
            });
          }
        } catch (e) {
          print("Error loading profile image for web: $e");
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
          _profileImageBase64 = base64Encode(bytes);
        });
      } else {
        setState(() {
          _profileImage = File(pickedFile.path);
          _profileImageBase64 = base64Encode(_profileImage!.readAsBytesSync());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تکمیل پروفایل')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text(
                        'شماره شما: ${convertEnglishDigitsToPersian(widget.phone)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : _profileImageBytes != null
                                    ? MemoryImage(_profileImageBytes!) as ImageProvider
                                    : null,
                            child: _profileImage == null && _profileImageBytes == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'نام'),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'نام را وارد کنید' : null,
                      ),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'نام خانوادگی'),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'نام خانوادگی را وارد کنید' : null,
                      ),
                      TextFormField(
                        controller: _fatherNameController,
                        decoration: const InputDecoration(labelText: 'نام پدر'),
                        validator: (value) =>
                            (value == null || value.trim().length < 3)
                                ? 'نام پدر حداقل ۳ کاراکتر باید باشد'
                                : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: 'جنسیت'),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('مرد')),
                          DropdownMenuItem(value: 'F', child: Text('زن')),
                        ],
                        onChanged: (value) => setState(() => _selectedGender = value),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'جنسیت را انتخاب کنید' : null,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'رمز عبور'),
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        validator: (value) =>
                            (value == null || value.length < 4) ? 'رمز باید حداقل ۴ رقم باشد' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : submitProfile,
                        child: const Text('ثبت اطلاعات'),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red, fontFamily: 'Vazir'),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      print("Submitting profile...");
      print("ImageBase64 length: ${_profileImageBase64?.length}");

      await AuthService.completeProfile(
        phone: widget.phone,
        firstName: convertPersianDigitsToEnglish(_firstNameController.text.trim()),
        lastName: convertPersianDigitsToEnglish(_lastNameController.text.trim()),
        fatherName: convertPersianDigitsToEnglish(_fatherNameController.text.trim()),
        password: convertPersianDigitsToEnglish(_passwordController.text.trim()),
        gender: _selectedGender,
        imageBase64: _profileImageBase64,
      );

      final updatedProfile = await AuthService.getProfile();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      Provider.of<UserProvider>(context, listen: false)
          .setUser(User.fromJson(updatedProfile), token: token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اطلاعات با موفقیت ثبت شد')),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      print("Error submitting profile: $e");
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }
}
