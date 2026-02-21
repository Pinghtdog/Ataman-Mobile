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

/// [ProfileScreen] is the main user dashboard for account and health management.
///
/// This screen provides a high-level overview of the user's identity and quick 
/// access to core features:
/// 1. **Identity & Verification**: Displays name, location, and PhilHealth status.
/// 2. **Activity Tracking**: Links to appointments, medical history, and referrals.
/// 3. **Medical Documentation**: Provides access to digital Medical ID and triage assessments.
/// 4. **Account Management**: Handles family members, profile editing, and app settings.
///
/// It coordinates data from [ProfileCubit] for real-time profile updates and 
/// [AuthCubit] for session lifecycle management.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Cached user data used to prevent UI flickering during profile reloads.
  UserModel? _cachedUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Triggers a profile reload from the repository via [ProfileCubit].
  void _loadProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<ProfileCubit>().loadProfile(authState.user.id);
    }
  }

  /// Displays the PhilHealth status modal, allowing users to view or initiate 
  /// verification updates.
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

  /// Displays a confirmation dialog before logging the user out.
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
          // Redirect to auth selection when session is terminated.
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
                                              _buildVerifiedBadge(),
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
                                _buildEditProfileButton(context, user),
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

                              _buildRecordsSection(context, user),
                              
                              const SizedBox(height: AppSizes.p16),
                              
                              _buildSettingsSection(context),

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

  /// Builds the PhilHealth verification badge for the header.
  Widget _buildVerifiedBadge() {
    return Container(
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
    );
  }

  /// Builds the button to navigate to the profile editing screen.
  Widget _buildEditProfileButton(BuildContext context, UserModel user) {
    return Align(
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
    );
  }

  /// Groups medical record links (Referrals, Triage History, Digital ID, PhilHealth).
  Widget _buildRecordsSection(BuildContext context, UserModel? user) {
    return Container(
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
            onTap: () => Navigator.pushNamed(context, AppRoutes.referrals),
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          ProfileListTile(
            title: "Medical Assessments",
            icon: Icons.history_edu_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.triageHistory),
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          ProfileListTile(
            title: "Digital Medical ID",
            icon: Icons.qr_code_scanner_rounded,
            onTap: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MedicalIdScreen(user: user)),
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
    );
  }

  /// Groups app-wide settings and support links.
  Widget _buildSettingsSection(BuildContext context) {
    return Container(
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
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          ProfileListTile(
            title: "Privacy Policy",
            icon: Icons.privacy_tip_outlined,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          ProfileListTile(
            title: "Terms & Conditions",
            icon: Icons.description_outlined,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          ProfileListTile(
            title: "Help & Support",
            icon: Icons.help_outline_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
