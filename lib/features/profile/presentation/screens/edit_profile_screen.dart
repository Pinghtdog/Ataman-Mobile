import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile_cubit.dart';
import '../../logic/profile_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/address_service.dart';
import '../../../../core/services/philhealth_service.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/utils/validator_utils.dart';
import '../../../../injector.dart';
import '../widgets/section_header.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _barangayController;
  late TextEditingController _philhealthController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  String? _selectedBloodType;
  String? _selectedGender;

  final AddressService _addressService = AddressService();
  List<String> _barangays = [];
  bool _isLoadingBarangays = true;
  late bool _isVerified;
  bool _isPhilhealthValid = false;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.user.isPhilhealthVerified;
    _isPhilhealthValid = _isVerified;
    
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _middleNameController = TextEditingController(text: widget.user.middleName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _barangayController = TextEditingController(text: widget.user.barangay);
    _philhealthController = TextEditingController(text: widget.user.philhealthId);
    _allergiesController = TextEditingController(text: widget.user.allergies);
    _conditionsController = TextEditingController(text: widget.user.medicalConditions);
    _emergencyNameController = TextEditingController(text: widget.user.emergencyContactName);
    _emergencyPhoneController = TextEditingController(text: widget.user.emergencyContactPhone);
    _selectedBloodType = widget.user.bloodType;
    _selectedGender = widget.user.gender;

    _philhealthController.addListener(_validatePhilhealth);
    _loadBarangays();
  }

  void _validatePhilhealth() {
    final isValid = getIt<PhilHealthService>().validatePIN(_philhealthController.text);
    if (isValid != _isPhilhealthValid) {
      setState(() => _isPhilhealthValid = isValid);
    }
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
      if (mounted) setState(() => _isLoadingBarangays = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _barangayController.dispose();
    _philhealthController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    
    // CLEAN PIN: Remove non-numeric characters before saving to match DB requirement
    final String cleanPIN = _philhealthController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final updatedUser = widget.user.copyWith(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      barangay: _barangayController.text.trim(),
      philhealthId: cleanPIN,
      allergies: _allergiesController.text.trim(),
      medicalConditions: _conditionsController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      bloodType: _selectedBloodType,
      gender: _selectedGender,
      isProfileComplete: true,
    );
    context.read<ProfileCubit>().updateProfile(updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) => current is ProfileSuccess || current is ProfileError,
        listener: (context, state) {
          if (state is ProfileSuccess) {
            context.read<AuthCubit>().refreshProfile(state.user);
            UiUtils.showSuccess(context, "Profile updated successfully!");
            Navigator.of(context).pop(true); // Return true to indicate update happened
          } else if (state is ProfileError) {
            UiUtils.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              AtamanHeader(
                isSimple: true,
                height: 120,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(false), // Return false for manual back
                    ),
                    const Expanded(
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: AtamanAvatar(radius: 50)),
                        const SizedBox(height: AppSizes.p32),
                        
                        const SectionHeader(title: "Identity & Verification"),
                        if (_isVerified)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "PHILHEALTH VERIFIED: Core identity fields are secured and cannot be modified.",
                                      style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const AtamanLabel(text: "PHILHEALTH ID"),
                        AtamanTextField(
                          label: "",
                          hintText: "Enter 12-digit PIN",
                          controller: _philhealthController,
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          readOnly: _isVerified,
                          suffixIcon: _isPhilhealthValid 
                            ? const Icon(Icons.check_circle, color: Colors.green) 
                            : null,
                          helperText: _isVerified 
                            ? "Verified PhilHealth identity cannot be changed." 
                            : "Enter 12 digits for instant verification",
                        ),
                        const SizedBox(height: AppSizes.p24),

                        AtamanTextField(
                          label: "First Name",
                          controller: _firstNameController,
                          prefixIcon: Icons.person_outline,
                          validator: ValidatorUtils.validateFirstName,
                          readOnly: _isVerified,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Middle Name",
                          controller: _middleNameController,
                          prefixIcon: Icons.person_outline,
                          readOnly: _isVerified,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Last Name",
                          controller: _lastNameController,
                          prefixIcon: Icons.person_outline,
                          validator: ValidatorUtils.validateLastName,
                          readOnly: _isVerified,
                        ),
                        
                        const SizedBox(height: AppSizes.p32),
                        const SectionHeader(title: "Contact Information"),
                        const SizedBox(height: AppSizes.p16),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: ValidatorUtils.validatePhoneNumber,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: InputDecoration(
                            labelText: "Mobile Number",
                            hintText: "09XXXXXXXXX",
                            prefixIcon: const Icon(Icons.phone_android_outlined, color: AppColors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        
                        const SizedBox(height: AppSizes.p16),
                        const AtamanLabel(text: "BARANGAY"),
                        DropdownButtonFormField<String>(
                          value: _barangayController.text.isEmpty ? null : _barangayController.text,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          hint: Text(_isLoadingBarangays ? "Loading..." : "Select Barangay"),
                          items: _barangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() => _barangayController.text = val!),
                          validator: (val) => val == null || val.isEmpty ? "Required" : null,
                        ),
                        
                        const SizedBox(height: AppSizes.p32),
                        const SectionHeader(title: "Medical Information"),
                        const SizedBox(height: AppSizes.p16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: "Gender",
                                value: _selectedGender,
                                items: ['Male', 'Female', 'Other', 'Prefer not to say'],
                                onChanged: _isVerified ? null : (val) => setState(() => _selectedGender = val),
                              ),
                            ),
                            const SizedBox(width: AppSizes.p16),
                            Expanded(
                              child: _buildDropdown(
                                label: "Blood Type",
                                value: _selectedBloodType,
                                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                                onChanged: (val) => setState(() => _selectedBloodType = val),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Allergies",
                          controller: _allergiesController,
                          prefixIcon: Icons.warning_amber_rounded,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Medical Conditions",
                          controller: _conditionsController,
                          prefixIcon: Icons.medical_information_outlined,
                        ),
    
                        const SizedBox(height: AppSizes.p32),
                        const SectionHeader(title: "Emergency Contact"),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Contact Name",
                          controller: _emergencyNameController,
                          prefixIcon: Icons.contact_emergency_outlined,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          keyboardType: TextInputType.phone,
                          validator: ValidatorUtils.validatePhoneNumber,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: InputDecoration(
                            labelText: "Contact Phone",
                            hintText: "09XXXXXXXXX",
                            prefixIcon: const Icon(Icons.phone_callback_outlined, color: AppColors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        
                        const SizedBox(height: AppSizes.p40),
                        AtamanButton(
                          text: "Save Changes",
                          onPressed: _saveProfile,
                          isLoading: state is ProfileLoading,
                        ),
                        const SizedBox(height: AppSizes.p24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: onChanged == null ? Colors.grey[100] : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text("Select"),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
