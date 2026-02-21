import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../logic/profile_cubit.dart';
import '../../logic/profile_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../auth/presentation/screens/philhealth_verification_screen.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/address_service.dart';
import '../../../../core/services/philhealth_service.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/utils/validator_utils.dart';
import '../../../../injector.dart';
import '../widgets/section_header.dart';

/// [EditProfileScreen] provides a secure interface for users to update their personal, 
/// contact, and medical information.
///
/// **Key Features:**
/// 1. **Identity Protection**: If the user's profile is PhilHealth verified, core 
///    identity fields (First Name, Last Name, Middle Name, Gender) are locked and 
///    become read-only to maintain data integrity.
/// 2. **PhilHealth Verification**: Allows unverified users to initiate identity 
///    validation via [PhilHealthVerificationScreen].
/// 3. **Smart Address Selection**: Fetches and provides a searchable list of 
///    official Naga City barangays via [AddressService].
/// 4. **Medical Profile**: Captures critical information such as blood type, 
///    allergies, and pre-existing conditions for better triage and care.
/// 5. **Emergency Contact**: Ensures emergency response coordination by 
///    collecting validated contact person details.
///
/// This screen synchronizes changes with both the [ProfileCubit] (for database 
/// persistence) and [AuthCubit] (for local session updates).
class EditProfileScreen extends StatefulWidget {
  /// The current user model containing existing profile data.
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
    // Initialize verification status based on the user's PhilHealth record validity.
    _isVerified = widget.user.isPhilhealthVerificationValid;
    _isPhilhealthValid = getIt<PhilHealthService>().validatePIN(widget.user.philhealthId ?? "");
    
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
    _selectedGender = _normalizeGender(widget.user.gender);

    _philhealthController.addListener(_validatePhilhealth);
    _loadBarangays();
  }

  /// Normalizes gender strings to match the predefined UI options.
  String? _normalizeGender(String? gender) {
    if (gender == null) return null;
    final items = ['Male', 'Female', 'Other', 'Prefer not to say'];
    try {
      return items.firstWhere(
        (i) => i.toLowerCase() == gender.toLowerCase(),
        orElse: () => items.contains(gender) ? gender : items.first,
      );
    } catch (e) {
      return null;
    }
  }

  /// Performs real-time validation of the PhilHealth PIN format.
  void _validatePhilhealth() {
    final isValid = getIt<PhilHealthService>().validatePIN(_philhealthController.text);
    if (isValid != _isPhilhealthValid) {
      setState(() => _isPhilhealthValid = isValid);
    }
  }

  /// Fetches the list of official Naga City barangays from the [AddressService].
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

  /// Validates the form and dispatches an update request via [ProfileCubit].
  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    
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
            Navigator.of(context).pop(true);
          } else if (state is ProfileError) {
            UiUtils.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              AtamanHeader(
                isSimple: true,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(false),
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
                          _buildVerifiedBanner(),
                        
                        const AtamanLabel(text: "PHILHEALTH ID"),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AtamanTextField(
                                label: "",
                                hintText: "Enter 12-digit PIN",
                                controller: _philhealthController,
                                prefixIcon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                readOnly: _isVerified,
                                suffixIcon: _isPhilhealthValid 
                                  ? const Icon(Icons.check_circle, color: Colors.green) 
                                  : null,
                              ),
                            ),
                            if (!_isVerified && _isPhilhealthValid) ...[
                              const SizedBox(width: 12),
                              _buildVerifyButton(),
                            ],
                          ],
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
                          isExpanded: true,
                          value: _barangayController.text.isEmpty ? null : (_barangays.contains(_barangayController.text) ? _barangayController.text : null),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          hint: Text(_isLoadingBarangays ? "Loading..." : "Select Barangay"),
                          items: _barangays.map((b) => DropdownMenuItem(
                            value: b, 
                            child: Text(b, overflow: TextOverflow.ellipsis)
                          )).toList(),
                          onChanged: (val) => setState(() => _barangayController.text = val!),
                          validator: (val) => val == null || val.isEmpty ? "Required" : null,
                        ),
                        
                        const SizedBox(height: AppSizes.p32),
                        const SectionHeader(title: "Medical Information"),
                        const SizedBox(height: AppSizes.p16),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: "Gender",
                                value: _selectedGender,
                                items: const ['Male', 'Female', 'Other', 'Prefer not to say'],
                                onChanged: _isVerified ? null : (val) => setState(() => _selectedGender = val),
                              ),
                            ),
                            const SizedBox(width: AppSizes.p12),
                            Expanded(
                              child: _buildDropdown(
                                label: "Blood",
                                value: _selectedBloodType,
                                items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                                onChanged: (val) => setState(() => _selectedBloodType = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Allergies",
                          controller: _allergiesController,
                          hintText: "e.g. Penicillin, Peanuts (Optional)",
                          prefixIcon: Icons.warning_amber_outlined,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Medical Conditions",
                          controller: _conditionsController,
                          hintText: "e.g. Hypertension, Diabetes (Optional)",
                          prefixIcon: Icons.history_edu_outlined,
                        ),

                        const SizedBox(height: AppSizes.p32),
                        const SectionHeader(title: "Emergency Contact"),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Contact Person Name",
                          controller: _emergencyNameController,
                          prefixIcon: Icons.contact_emergency_outlined,
                          validator: (val) => val != null && val.isNotEmpty && val.length < 3 ? "Invalid name" : null,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        AtamanTextField(
                          label: "Contact Person Phone",
                          controller: _emergencyPhoneController,
                          prefixIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              return ValidatorUtils.validatePhoneNumber(val);
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSizes.p48),
                        AtamanButton(
                          text: "Save Profile",
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

  /// Builds a visual indicator showing that the user's identity is PhilHealth verified.
  Widget _buildVerifiedBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "PHILHEALTH VERIFIED: Core identity fields are secured.",
                    style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (widget.user.philhealthVerifiedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                "Expires on: ${DateFormat('MMM dd, yyyy').format(widget.user.philhealthVerifiedAt!.add(const Duration(days: 3)))}",
                style: TextStyle(color: Colors.blue.withOpacity(0.7), fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the "VERIFY" button which launches the PhilHealth verification flow.
  Widget _buildVerifyButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AtamanButton(
        text: "VERIFY",
        width: 100,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhilHealthVerificationScreen(user: widget.user),
            ),
          );
          if (result == true) {
            await Future.delayed(const Duration(milliseconds: 500));
            await context.read<AuthCubit>().getProfile();
            final authState = context.read<AuthCubit>().state;
            if (authState is Authenticated && authState.profile != null) {
              setState(() {
                _isVerified = true;
                _firstNameController.text = authState.profile!.firstName;
                _lastNameController.text = authState.profile!.lastName;
                _middleNameController.text = authState.profile!.middleName ?? "";
                _philhealthController.text = authState.profile!.philhealthId ?? "";
                _selectedGender = _normalizeGender(authState.profile!.gender);
              });
            } else {
              setState(() => _isVerified = true);
            }
          }
        },
      ),
    );
  }

  /// Generic helper widget for building styled dropdown menus.
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    final String? effectiveValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtamanLabel(text: label),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: effectiveValue,
          onChanged: onChanged,
          items: items.map((i) => DropdownMenuItem(
            value: i, 
            child: Text(i, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
          )).toList(),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
        ),
      ],
    );
  }
}
