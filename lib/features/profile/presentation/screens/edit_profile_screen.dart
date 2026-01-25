import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile_cubit.dart';
import '../../logic/profile_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/address_service.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/utils/validator_utils.dart';
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

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _isVerified = widget.user.philhealthId != null && widget.user.philhealthId!.isNotEmpty;
    
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _middleNameController = TextEditingController(text: widget.user.middleName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _barangayController = TextEditingController(text: widget.user.barangay);
    _allergiesController = TextEditingController(text: widget.user.allergies);
    _conditionsController = TextEditingController(text: widget.user.medicalConditions);
    _emergencyNameController = TextEditingController(text: widget.user.emergencyContactName);
    _emergencyPhoneController = TextEditingController(text: widget.user.emergencyContactPhone);
    _selectedBloodType = widget.user.bloodType;
    _selectedGender = widget.user.gender;
    _loadBarangays();
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
    _allergiesController.dispose();
    _conditionsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    
    final updatedUser = widget.user.copyWith(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      barangay: _barangayController.text.trim(),
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
        listener: (context, state) {
          if (state is ProfileSuccess) {
            UiUtils.showSuccess(context, "Profile updated successfully!");
            if (Navigator.canPop(context)) Navigator.of(context).pop();
          } else if (state is ProfileError) {
            UiUtils.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              AtamanSimpleHeader(
                height: 120,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
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
                        
                        const SectionHeader(title: "Personal Information"),
                        if (_isVerified)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: AtamanBadge.success(text: "VERIFIED PROFILE - IDENTITY LOCKED"),
                          ),
                        const SizedBox(height: AppSizes.p16),
                        
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
                                items: _genders,
                                onChanged: _isVerified ? null : (val) => setState(() => _selectedGender = val),
                              ),
                            ),
                            const SizedBox(width: AppSizes.p16),
                            Expanded(
                              child: _buildDropdown(
                                label: "Blood Type",
                                value: _selectedBloodType,
                                items: _bloodTypes,
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
