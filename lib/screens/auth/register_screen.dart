import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/ataman_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _barangayController = TextEditingController();
  final _philhealthController = TextEditingController();

  void _onContinue() {
    if (_nameController.text.isNotEmpty &&
        _birthdateController.text.isNotEmpty &&
        _barangayController.text.isNotEmpty) {
      
      final profileData = {
        'fullName': _nameController.text.trim(),
        'birthDate': _birthdateController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'philhealthId': _philhealthController.text.trim(),
      };

      Navigator.pushNamed(
        context,
        '/verify-id',
        arguments: profileData,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Profile",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please provide accurate information.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            _buildLabel("FULL NAME"),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Juan Dela Cruz",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel("BIRTHDATE"),
            TextField(
              controller: _birthdateController,
              decoration: const InputDecoration(
                hintText: "12 / 05 / 1989",
                border: UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 24),

            _buildLabel("BARANGAY"),
            TextField(
              controller: _barangayController,
              decoration: const InputDecoration(
                hintText: "Concepcion Pequeña",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel("PHILHEALTH ID (OPTIONAL)"),
            TextField(
              controller: _philhealthController,
              decoration: const InputDecoration(
                hintText: "00-000000000-0",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 48),

            AtamanButton(
              text: "Continue",
              onPressed: _onContinue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
}
