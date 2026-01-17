import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../widgets/ataman_avatar.dart';
import '../../widgets/ataman_logout_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.authSelection,
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          String fullName = "User Name";
          String email = "email@example.com";

          if (state is Authenticated && state.user != null) {
            fullName = state.profile?.fullName ?? "User Name";
            email = state.user!.email ?? "email@example.com";
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, bottom: 50),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(AppSizes.p24),
                        bottomRight: Radius.circular(AppSizes.p24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryLight.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: const AtamanAvatar(radius: 40),
                        ),
                        const SizedBox(height: AppSizes.p12),
                        Text(
                          fullName,
                          style: AppTextStyles.h2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSizes.p4),
                        Text(
                          email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: AppSizes.p12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p16,
                            vertical: AppSizes.p4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppSizes.p20),
                          ),
                          child: Text(
                            "Naga City Resident",
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Section
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                      padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.p24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.badge_outlined,
                            title: "My Naga ID",
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.folder_shared_outlined,
                            title: "Medical History",
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.assignment_outlined,
                            title: "Triage Results",
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.logout_rounded,
                            title: "Logout",
                            onTap: () => _showLogoutDialog(context),
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p4,
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.danger.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.danger : AppColors.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.danger : AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.textSecondary.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 80,
      endIndent: 24,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AtamanLogoutDialog(
        onLogout: () {
          context.read<AuthCubit>().logout();
        },
      ),
    );
  }
}
