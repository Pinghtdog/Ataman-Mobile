import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/services/address_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/utils/validator_utils.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _barangayController = TextEditingController();
  final _philhealthController = TextEditingController();
  final _medicalIdController = TextEditingController(); // For Record Syncing
  
  DateTime? _selectedDate;
  
  final AddressService _addressService = AddressService();
  List<String> _barangays = [];
  bool _isLoadingBarangays = true;
  bool _isSyncingRecords = false;

  @override
  void initState() {
    super.initState();
    _loadBarangays();
    
    // Check if we came from the Medical ID Sync flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['is_medical_id_sync'] == true) {
        setState(() {
          _isSyncingRecords = true;
        });
        _showScannerDialog();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _barangayController.dispose();
    _philhealthController.dispose();
    _medicalIdController.dispose();
    super.dispose();
  }

  void _showScannerDialog() {
    // Simulated Scanner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Sync Medical Records"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please scan the QR code given to you by the hospital or ambulance staff to sync your records."),
            const SizedBox(height: 16),
            AtamanTextField(
              label: "MEDICAL ID",
              hintText: "ATAM-XXXXXXXX",
              controller: _medicalIdController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_medicalIdController.text.isNotEmpty) {
                Navigator.pop(context);
                UiUtils.showSuccess(context, "Medical ID linked. Your records will be synced after setup.");
              }
            },
            child: const Text("LINK ID"),
          ),
        ],
      ),
    );
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
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'birthDate': _birthdateController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'philhealthId': _philhealthController.text.trim(),
        'medicalId': _medicalIdController.text.trim(), 
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
                  _isSyncingRecords ? "Setup Official Account" : "Create Profile",
                  style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  _isSyncingRecords 
                    ? "Complete your profile to sync your hospital records."
                    : "Please provide accurate information.",
                  style: AppTextStyles.bodyMedium,
                ),

                if (_isSyncingRecords && _medicalIdController.text.isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(top: AppSizes.p16),
                     child: Container(
                       padding: const EdgeInsets.all(AppSizes.p12),
                       decoration: BoxDecoration(
                         color: AppColors.primary.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                         border: Border.all(color: AppColors.primary),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.sync_outlined, color: AppColors.primary),
                           const SizedBox(width: 8),
                           Text(
                             "ID Linked: ${_medicalIdController.text}",
                             style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     ),
                   ),

                const SizedBox(height: AppSizes.p32),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AtamanLabel(text: "FIRST NAME"),
                          AtamanTextField(
                            label: "",
                            hintText: "Juan",
                            controller: _firstNameController,
                            prefixIcon: Icons.person_outline,
                            validator: ValidatorUtils.validateFirstName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.p16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AtamanLabel(text: "LAST NAME"),
                          AtamanTextField(
                            label: "",
                            hintText: "Dela Cruz",
                            controller: _lastNameController,
                            prefixIcon: Icons.person_outline,
                            validator: ValidatorUtils.validateLastName,
                          ),
                        ],
                      ),
                    ),
                  ],
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
