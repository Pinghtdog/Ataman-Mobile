import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../widgets/ataman_button.dart';
import '../../widgets/ataman_text_field.dart';

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
  DateTime? _selectedDate;

  //for the mock data
  final List<String> _nagaBarangays = [
    "Abella", "Bagumbayan Norte", "Bagumbayan Sur", "Balatas", "Calauag", 
    "Cararayan", "Carolina", "Concepcion Grande", "Concepcion Pequeña", 
    "Dayangdang", "Del Rosario", "Dinaga", "Igualdad Interior", "Lerma", 
    "Liboton", "Mabolo", "Pacol", "Panicuason", "Peñafrancia", "Sabang", 
    "San Felipe", "San Francisco", "San Isidro", "Santa Cruz", "Tabuco", 
    "Tinago", "Triangulo"
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdateController.text = DateFormat('MM / dd / yyyy').format(picked);
      });
    }
  }

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
            AtamanTextField(
              label: "",
              controller: _nameController,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 24),

            _buildLabel("BIRTHDATE"),
            InkWell(
              onTap: () => _selectDate(context),
              child: IgnorePointer(
                child: AtamanTextField(
                  label: "",
                  controller: _birthdateController,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel("BARANGAY"),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xB300695C)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              hint: const Text("Select Barangay"),
              items: _nagaBarangays.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _barangayController.text = newValue!;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildLabel("PHILHEALTH ID (OPTIONAL)"),
            AtamanTextField(
              label: "00-000000000-0",
              controller: _philhealthController,
              prefixIcon: Icons.badge_outlined,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
