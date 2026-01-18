import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../widgets/ataman_avatar.dart';
import '../../widgets/ataman_header.dart';
import '../../widgets/profile/profile_feature_card.dart';
import '../../widgets/profile/profile_list_tile.dart';
import '../../widgets/profile/profile_square_card.dart';
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
          String fullName = "Guest";
          String address = "Naga City Resident";
          String idStatus = "UNVERIFIED";
          Color statusColor = Colors.grey;

          if (state is Authenticated && state.user != null) {
            fullName = state.profile?.fullName ?? state.user!.userMetadata?['full_name'] ?? "User";
            address = state.profile?.barangay != null ? "${state.profile!.barangay}, Naga City" : "Naga City Resident";
            
            if (state.profile?.isProfileComplete ?? false) {
              idStatus = "VERIFIED";
              statusColor = AppColors.success;
            }
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AtamanHeader(
                    height: 200,
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                          child: const AtamanAvatar(radius: 35),
                        ),
                        const SizedBox(width: AppSizes.p20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: AppTextStyles.h2.copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  //
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSizes.p20),

                        ProfileFeatureCard(
                          title: "Digital Medical ID",
                          subtitle: "QR Code for Hospital/BHC",
                          icon: Icons.qr_code_scanner_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primary.withOpacity(0.1),
                          onTap: () {},
                        ),

                        const SizedBox(height: AppSizes.p16),

                        Row(
                          children: [
                            Expanded(
                              child: ProfileSquareCard(
                                title: "Medical History",
                                subtitle: "Records & Labs",
                                icon: Icons.history_edu_rounded,
                                iconColor: Colors.orange[800]!,
                                iconBg: Colors.orange[50]!,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: AppSizes.p16),
                            Expanded(
                              child: ProfileSquareCard(
                                title: "Family Members",
                                subtitle: "Manage Dependents",
                                icon: Icons.diversity_1_rounded,
                                iconColor: Colors.blue[800]!,
                                iconBg: Colors.blue[50]!,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.p16),

                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ProfileListTile(
                                title: "Indigency Verification",
                                icon: Icons.verified_user_outlined,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall)
                                  ),
                                  child: Text(
                                    idStatus,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () {},
                              ),
                              const Divider(height: 1, indent: 60, endIndent: 20),
                              ProfileListTile(
                                title: "Settings",
                                icon: Icons.settings_outlined,
                                onTap: () {},
                              ),
                              const Divider(height: 1, indent: 60, endIndent: 20),
                              ProfileListTile(
                                title: "Log Out",
                                icon: Icons.logout_rounded,
                                iconColor: AppColors.danger,
                                titleColor: AppColors.danger,
                                onTap: () => _showLogoutDialog(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
