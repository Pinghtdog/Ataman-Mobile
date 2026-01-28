import 'package:ataman/core/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../emergency/presentation/widgets/emergency_help_card.dart';
import '../widgets/smart_triage_card.dart';

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
            // physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(
                  height: 340,
                  child: Stack(
                    children: [
                      AtamanHeader(
                        height: 240,
                        child: SafeArea(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Maogmang Aga,",
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
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pushNamed(AppRoutes.notifications);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSizes.p8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: AppSizes.iconMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SmartTriageCard(
                          onTap: () {
                            debugPrint("Triage Card Tapped");
                            Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.triage);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.p24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Services",
                        style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSizes.p8),
                      AtamanServiceGrid(
                        services: const [
                          {'title': 'Medicine Access',
                            'icon': Icons.medical_services_rounded,
                            'color': Color(0xFF6A1B9A),
                          },
                          {'title': 'Health Alerts',
                            'icon': Icons.warning_amber_rounded,
                            'color': Color(0xFFF57C00),
                          },
                          {'title': 'Reproductive',
                            'icon': Icons.favorite_outline_rounded,
                            'color': Color(0xFFAD1457),
                          },
                          {'title': 'Vaccines',
                            'icon': Icons.vaccines_rounded,
                            'color': Color(0xFF1976D2),
                          },
                        ],
                        onServiceTap: (index) {
                          if (index == 0) { // 'Medicine Access'
                            Navigator.of(context).pushNamed(AppRoutes.medicineAccess);
                          } else if (index == 1) { // 'Health Alerts'
                            Navigator.of(context).pushNamed(AppRoutes.healthAlerts);
                          } else if (index == 2) { // 'Reproductive'
                            Navigator.of(context).pushNamed(AppRoutes.reproductiveHealth);
                          } else if (index == 3) { // 'Vaccines'
                            Navigator.of(context).pushNamed(AppRoutes.vaccination);
                          }
                        },
                      ),
                      const SizedBox(height: AppSizes.p32),

                      EmergencyHelpCard(
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.emergency);
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
