import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../widgets/family_member_card.dart';
import 'package:dotted_border/dotted_border.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        UserModel? primaryUser;
        if (authState is Authenticated) {
          primaryUser = authState.profile;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AtamanSimpleHeader(
                height: 120,
                padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Family Members",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionHeader("PRIMARY PROFILE"),
                    if (primaryUser != null)
                      _buildPrimaryProfileCard(primaryUser)
                    else
                      const Center(child: CircularProgressIndicator()),
                    
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader("DEPENDENTS"),
                    // Mock data for display, in real app this would come from a repository
                    FamilyMemberCard(
                      name: "Maria Dela Cruz",
                      relationship: "Spouse",
                      age: 32,
                      avatarColor: Colors.pink.shade50,
                      iconColor: Colors.pink,
                      onViewId: () {},
                    ),
                    const SizedBox(height: 16),
                    FamilyMemberCard(
                      name: "Miguel Dela Cruz",
                      relationship: "Son",
                      age: 5,
                      avatarColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      onViewId: () {},
                    ),
                    const SizedBox(height: 16),
                    FamilyMemberCard(
                      name: "Lola Rosa",
                      relationship: "Mother",
                      age: 72,
                      avatarColor: Colors.orange.shade50,
                      iconColor: Colors.orange,
                      onViewId: () {},
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Add Family Member Button
                    DottedBorder(
                      color: AppColors.primary,
                      strokeWidth: 2,
                      dashPattern: const [8, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(20),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                "Add Family Member",
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPrimaryProfileCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Active Account",
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
        ],
      ),
    );
  }
}
