import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../widgets/ataman_header.dart';
import '../../widgets/ataman_service_grid.dart';
import '../../widgets/emergency/emergency_help_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String userName = "User";
        if (state is Authenticated) {
          userName = state.profile?.fullName.split(' ').first ?? "User";
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                AtamanHeader(
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello,",
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              userName,
                              style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(AppSizes.p8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: AppSizes.iconMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EmergencyHelpCard(
                        onTap: () {
                          // TODO: Navigate to emergency screen
                        },
                      ),
                      const SizedBox(height: AppSizes.p32),
                      Text(
                        "Our Services",
                        style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSizes.p16),
                      AtamanServiceGrid(
                        services: const [
                          {'title': 'Triage', 'icon': Icons.medical_services_rounded, 'color': Color(0xFF2196F3)},
                          {'title': 'Booking', 'icon': Icons.calendar_month_rounded, 'color': Color(0xFFFF9800)},
                          {'title': 'Telemed', 'icon': Icons.video_camera_front_rounded, 'color': Color(0xFF4CAF50)},
                          {'title': 'Records', 'icon': Icons.history_rounded, 'color': Color(0xFF9C27B0)},
                        ],
                        onServiceTap: (index) {
                          // TODO: Handle service navigation
                        },
                      ),
                      const SizedBox(height: AppSizes.p32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
