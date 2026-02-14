import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../injector.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../emergency/presentation/widgets/emergency_help_card.dart';
import '../../../notification/logic/notification_cubit.dart';
import '../../../notification/logic/notification_state.dart';
import '../widgets/smart_triage_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _setupScanListener();
  }

  void _setupScanListener() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      // Start listening for real-time QR scan events (Sync with Web Portal)
      getIt<NotificationService>().listenToScanEvents(authState.user.id);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Maogmang Aga"; // Good Morning
    } else if (hour < 18) {
      return "Maogmang Hapon"; // Good Afternoon
    } else {
      return "Maogmang Banggi"; // Good Evening
    }
  }

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
            child: Column(
              children: [
                SizedBox(
                  height: 380,
                  child: Stack(
                    children: [
                      AtamanHeader(
                        height: 240,
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${_getGreeting()},",
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      userName,
                                      style: AppTextStyles.h2.copyWith(
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSizes.p16),
                              _buildNotificationIcon(context),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
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

  Widget _buildNotificationIcon(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoaded) {
          unreadCount = state.notifications.where((n) => !n.isRead).length;
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.notifications);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
              if (unreadCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
