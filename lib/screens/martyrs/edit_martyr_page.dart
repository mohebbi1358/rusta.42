import 'package:flutter/material.dart';

class EditMartyrPage extends StatefulWidget {
  final Map<String, dynamic> martyr;

  const EditMartyrPage({super.key, required this.martyr});

  @override
  State<EditMartyrPage> createState() => _EditMartyrPageState();
}

class _EditMartyrPageState extends State<EditMartyrPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.martyr['first_name']);
    _lastNameController =
        TextEditingController(text: widget.martyr['last_name']);
  }

  void _saveMartyr() {
    if (_formKey.currentState!.validate()) {
      // TODO: ارسال تغییرات به API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تغییرات ذخیره شد")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ویرایش شهید")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: "نام"),
                validator: (v) =>
                    v == null || v.isEmpty ? "نام الزامی است" : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: "نام خانوادگی"),
                validator: (v) =>
                    v == null || v.isEmpty ? "نام خانوادگی الزامی است" : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveMartyr,
                child: const Text("ذخیره تغییرات"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
