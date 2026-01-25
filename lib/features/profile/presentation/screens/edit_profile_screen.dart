import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile_cubit.dart';
import '../../logic/profile_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _barangayController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  String? _selectedBloodType;
  String? _selectedGender;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _barangayController = TextEditingController(text: widget.user.barangay);
    _allergiesController = TextEditingController(text: widget.user.allergies);
    _conditionsController = TextEditingController(text: widget.user.medicalConditions);
    _emergencyNameController = TextEditingController(text: widget.user.emergencyContactName);
    _emergencyPhoneController = TextEditingController(text: widget.user.emergencyContactPhone);
    _selectedBloodType = widget.user.bloodType;
    _selectedGender = widget.user.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _barangayController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final updatedUser = widget.user.copyWith(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text,
      barangay: _barangayController.text,
      allergies: _allergiesController.text,
      medicalConditions: _conditionsController.text,
      emergencyContactName: _emergencyNameController.text,
      emergencyContactPhone: _emergencyPhoneController.text,
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile updated successfully!"),
                backgroundColor: AppColors.success,
              ),
            );
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
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
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold
                        ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: AtamanAvatar(radius: 50),
                      ),
                      const SizedBox(height: AppSizes.p32),
                      
                      const _SectionHeader(title: "Personal Information"),
                      const SizedBox(height: AppSizes.p16),
                      AtamanTextField(
                        label: "Full Name",
                        prefixIcon: Icons.person_outline_rounded,
                        controller: _nameController,
                      ),
                      const SizedBox(height: AppSizes.p16),
                      AtamanTextField(
                        label: "Phone Number",
                        prefixIcon: Icons.phone_android_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSizes.p16),
                      AtamanTextField(
                        label: "Barangay",
                        prefixIcon: Icons.location_on_outlined,
                        controller: _barangayController,
                      ),
                      
                      const SizedBox(height: AppSizes.p32),
                      const _SectionHeader(title: "Medical Information"),
                      const SizedBox(height: AppSizes.p16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: "Gender",
                              value: _selectedGender,
                              items: _genders,
                              onChanged: (val) => setState(() => _selectedGender = val),
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
                        hintText: "e.g. Peanuts, Penicillin",
                        prefixIcon: Icons.warning_amber_rounded,
                        controller: _allergiesController,
                      ),
                      const SizedBox(height: AppSizes.p16),
                      AtamanTextField(
                        label: "Medical Conditions",
                        hintText: "e.g. Hypertension, Diabetes",
                        prefixIcon: Icons.medical_information_outlined,
                        controller: _conditionsController,
                      ),

                      const SizedBox(height: AppSizes.p32),
                      const _SectionHeader(title: "Emergency Contact"),
                      const SizedBox(height: AppSizes.p16),
                      AtamanTextField(
                        label: "Contact Name",
                        prefixIcon: Icons.contact_emergency_outlined,
                        controller: _emergencyNameController,
                      ),
                      const SizedBox(height: AppSizes.p16),
                      AtamanTextField(
                        label: "Contact Phone",
                        prefixIcon: Icons.phone_callback_outlined,
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      
                      const SizedBox(height: AppSizes.p32),
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
    required Function(String?) onChanged,
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
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text("Select", style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(fontSize: 16),
        ),
      ],
    );
  }
}
