import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/constants.dart';
import '../../widgets/ataman_button.dart';
import '../../widgets/ataman_text_field.dart';
import '../../widgets/ataman_label.dart';
import '../../services/address_service.dart';

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
  
  final AddressService _addressService = AddressService();
  List<String> _barangays = [];
  bool _isLoadingBarangays = true;

  @override
  void initState() {
    super.initState();
    _loadBarangays();
  }

  Future<void> _loadBarangays() async {
    final list = await _addressService.getNagaBarangays();
    if (mounted) {
      setState(() {
        _barangays = list;
        _isLoadingBarangays = false;
      });
    }
  }

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
        AppRoutes.verifyId,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Profile",
              style: AppTextStyles.h1.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              "Please provide accurate information.",
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.p32),
            
            const AtamanLabel(text: "FULL NAME"),
            AtamanTextField(
              label: "",
              hintText: "Juan Dela Cruz",
              controller: _nameController,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: AppSizes.p24),

            const AtamanLabel(text: "BIRTHDATE"),
            InkWell(
              onTap: () => _selectDate(context),
              child: IgnorePointer(
                child: AtamanTextField(
                  label: "",
                  hintText: "MM / DD / YYYY",
                  controller: _birthdateController,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            const AtamanLabel(text: "BARANGAY"),
            _isLoadingBarangays 
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _barangayController.text.isEmpty ? null : _barangayController.text,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xB300695C)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.p12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text("Select Barangay"),
                  items: _barangays.map((String value) {
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
            const SizedBox(height: AppSizes.p24),

            const AtamanLabel(text: "PHILHEALTH ID (OPTIONAL)"),
            AtamanTextField(
              label: "",
              hintText: "00-000000000-0",
              controller: _philhealthController,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: AppSizes.p48),

            AtamanButton(
              text: "Continue",
              onPressed: _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
