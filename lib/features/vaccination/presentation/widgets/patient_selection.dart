import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../profile/data/model/family_member_model.dart';
import '../../../profile/logic/family_cubit.dart';

class PatientSelection extends StatelessWidget {
  final dynamic selectedPatient;
  final ValueChanged<dynamic> onChanged;

  const PatientSelection({
    super.key,
    required this.selectedPatient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyCubit, FamilyState>(
      builder: (context, state) {
        List<FamilyMember> members = [];
        bool isLoading = false;

        if (state is FamilyLoaded) {
          members = state.members;
        } else if (state is FamilyLoading) {
          isLoading = true;
        }

        final authState = context.read<AuthCubit>().state;
        String myName = 'Myself';
        if (authState is Authenticated) {
          myName = authState.profile?.fullName ?? 'Myself';
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "Myself" option
                _buildPatientCard(
                  context, 
                  myName, 
                  isSelected: selectedPatient == 'Myself' || selectedPatient == myName,
                  onTap: () => onChanged('Myself'),
                ),
                
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),

                // Family Members from database
                ...members.map((member) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildPatientCard(
                    context, 
                    member.fullName,
                    subtitle: member.relationship,
                    isSelected: selectedPatient is FamilyMember ? selectedPatient.id == member.id : selectedPatient == member.fullName,
                    onTap: () => onChanged(member),
                  ),
                )),

                const SizedBox(width: 12),
                _buildAddPatientCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(
    BuildContext context, 
    String name, {
    String? subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
              child: Icon(
                Icons.person,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? AppColors.primary.withOpacity(0.7) : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPatientCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/family-members'); // Adjust to your actual route
      },
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: Colors.grey[400]!,
        strokeWidth: 1,
        dashPattern: const [4, 4],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Icon(Icons.add, color: Colors.grey),
              SizedBox(height: 8),
              Text('Add', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
