import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/constants.dart';
import '../../widgets/ataman_button.dart';
import '../../widgets/ataman_text_field.dart';
import '../../widgets/ataman_label.dart';
import '../../services/address_service.dart';
import '../../utils/ui_utils.dart';
import '../../utils/validator_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
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

  @override
  void dispose() {
    _nameController.dispose();
    _birthdateController.dispose();
    _barangayController.dispose();
    _philhealthController.dispose();
    super.dispose();
  }

  Future<void> _loadBarangays() async {
    try {
      final list = await _addressService.getNagaBarangays();
      if (mounted) {
        setState(() {
          _barangays = list;
          _isLoadingBarangays = false;
        });
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showError(context, "Failed to load barangays.");
        setState(() => _isLoadingBarangays = false);
      }
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
              onSurface: AppColors.textPrimary,
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
    UiUtils.hideKeyboard(context);
    if (_formKey.currentState!.validate()) {
      if (_barangayController.text.isEmpty) {
        UiUtils.showError(context, "Please select your barangay");
        return;
      }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.p8),
                Text(
                  "Create Profile",
                  style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSizes.p8),
                const Text(
                  "Please provide accurate information.",
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSizes.p32),
                
                const AtamanLabel(text: "FULL NAME"),
                AtamanTextField(
                  label: "",
                  hintText: "Juan Dela Cruz",
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: ValidatorUtils.validateFullName,
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
                      validator: (value) => value == null || value.isEmpty ? "Birthdate is required" : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p24),
        
                const AtamanLabel(text: "BARANGAY"),
                DropdownButtonFormField<String>(
                  value: _barangayController.text.isEmpty ? null : _barangayController.text,
                  dropdownColor: AppColors.surface,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    suffixIcon: _isLoadingBarangays
                      ? const Padding(
                          padding: EdgeInsets.all(AppSizes.p12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                          ),
                        )
                      : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
                  ),
                  hint: Text(
                    _isLoadingBarangays ? "Loading barangays..." : "Select Barangay",
                    style: AppTextStyles.bodyMedium
                  ),
                  items: _isLoadingBarangays
                    ? []
                    : _barangays.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: _isLoadingBarangays ? null : (newValue) {
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
                const SizedBox(height: AppSizes.p32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
