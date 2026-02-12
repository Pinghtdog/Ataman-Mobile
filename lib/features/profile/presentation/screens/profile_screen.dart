import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/philhealth_service.dart';
import '../../../../core/widgets/ataman_logout_dialog.dart';
import '../../../../injector.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/profile_cubit.dart';
import '../../logic/profile_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../widgets/profile_feature_card.dart';
import '../widgets/profile_square_card.dart';
import '../widgets/profile_list_tile.dart';
import '../widgets/philhealth_status_modal.dart';
import 'edit_profile_screen.dart';
import 'medical_id_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _cachedUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<ProfileCubit>().loadProfile(authState.user.id);
    }
  }

  void _showPhilHealthStatus(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhilHealthStatusModal(
        user: user,
        onUpdatePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(user: user),
            ),
          ).then((value) {
            // Only reload if the Edit screen confirmed a change
            if (value == true) _loadProfile();
          });
        },
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AtamanLogoutDialog(
        onLogout: () async {
          await context.read<AuthCubit>().logout();
        },
      ),
    );
  }

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
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          if (profileState is ProfileSuccess) {
            _cachedUser = profileState.user;
          }

          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              String fullName = "Guest";
              String address = "Naga City Resident";
              bool isPhilhealthVerified = false;

              final user = profileState is ProfileSuccess ? profileState.user : _cachedUser;

              if (user != null) {
                fullName = user.fullName;
                address = user.barangay != null 
                    ? "${user.barangay}, Naga City" 
                    : "Naga City Resident";
                
                // ULTIMATE DEFENSIVE CHECK: Prevents crash from stale cache or hot reload issues.
                isPhilhealthVerified = user.isPhilhealthVerified;
              } else if (authState is Authenticated) {
                fullName = authState.profile?.fullName ?? 
                          "${authState.user.userMetadata?['first_name'] ?? ''} ${authState.user.userMetadata?['last_name'] ?? ''}".trim();
                if (fullName.isEmpty) fullName = "User";
                address = authState.profile?.barangay != null ? "${authState.profile!.barangay}, Naga City" : "Naga City Resident";
                isPhilhealthVerified = authState.profile?.isPhilhealthVerified ?? false;
              }

              return Scaffold(
                backgroundColor: AppColors.background,
                body: RefreshIndicator(
                  onRefresh: () async {
                    _loadProfile();
                    await context.read<ProfileCubit>().stream.firstWhere((state) => state is! ProfileLoading);
                  },
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        AtamanHeader(
                          height: 240,
                          padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
                          child: Column(
                            children: [
                              Row(
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fullName,
                                                style: AppTextStyles.h2.copyWith(color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPhilhealthVerified)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "PhilHealth Verified",
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
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
                              const SizedBox(height: 10),
                              if (user != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfileScreen(user: user),
                                        ),
                                      ).then((value) {
                                        if (value == true) _loadProfile();
                                      });
                                    },
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 12),
                                    label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                          child: Column(
                            children: [
                              const SizedBox(height: AppSizes.p20),

                              ProfileFeatureCard(
                                title: "My Appointments",
                                subtitle: "View and manage bookings",
                                icon: Icons.calendar_month_rounded,
                                iconColor: AppColors.primary,
                                iconBg: AppColors.primary.withOpacity(0.1),
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.myAppointments);
                                },
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
                                      onTap: () {
                                        Navigator.pushNamed(context, AppRoutes.medicalHistory);
                                      },
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
                                      onTap: () {
                                        Navigator.pushNamed(context, AppRoutes.familyMembers);
                                      },
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
                                      title: "Active Referrals",
                                      icon: Icons.assignment_turned_in_rounded,
                                      onTap: () {
                                        Navigator.pushNamed(context, AppRoutes.referrals);
                                      },
                                    ),
                                    const Divider(height: 1, indent: 60, endIndent: 20),
                                    ProfileListTile(
                                      title: "Digital Medical ID",
                                      icon: Icons.qr_code_scanner_rounded,
                                      onTap: () {
                                        if (user != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MedicalIdScreen(user: user),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    const Divider(height: 1, indent: 60, endIndent: 20),
                                    ProfileListTile(
                                      title: "PhilHealth Verification",
                                      icon: Icons.badge_outlined,
                                      onTap: () {
                                        if (user != null) _showPhilHealthStatus(user);
                                      },
                                    ),
                                  ],
                                ),
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
                                      title: "Settings",
                                      icon: Icons.settings_outlined,
                                      onTap: () {
                                        Navigator.pushNamed(context, AppRoutes.settings);
                                      },
                                    ),
                                    const Divider(height: 1, indent: 60, endIndent: 20),
                                    ProfileListTile(
                                      title: "Privacy Policy",
                                      icon: Icons.privacy_tip_outlined,
                                      onTap: () {
                                        // TODO: Navigate to Privacy Policy screen/webview
                                      },
                                    ),
                                    const Divider(height: 1, indent: 60, endIndent: 20),
                                    ProfileListTile(
                                      title: "Terms & Conditions",
                                      icon: Icons.description_outlined,
                                      onTap: () {
                                        // TODO: Navigate to Terms screen/webview
                                      },
                                    ),
                                    const Divider(height: 1, indent: 60, endIndent: 20),
                                    ProfileListTile(
                                      title: "Help & Support",
                                      icon: Icons.help_outline_rounded,
                                      onTap: () {
                                        // TODO: Navigate to Help screen/webview
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSizes.p40),
                              AtamanButton(
                                text: "Log Out",
                                color: Colors.white,
                                textColor: AppColors.danger,
                                onPressed: _handleLogout,
                              ),
                              const SizedBox(height: AppSizes.p40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
