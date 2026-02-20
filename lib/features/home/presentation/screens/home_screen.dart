import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      getIt<NotificationService>().listenToScanEvents(authState.user.id);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Marhay na Aga";
    if (hour < 18) return "Marhay na Hapon";
    return "Marhay na Banggi";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String userName = "User";
        String medicalId = "ATAMAN-ID-PENDING";
        if (state is Authenticated) {
          userName = state.profile?.fullName.split(' ').first ?? "User";
          medicalId = state.profile?.medicalId ?? "ATAMAN-ID-PENDING";
        }

        // Standardized JSON QR Data
        final String qrData = jsonEncode({
          "type": "MEDICAL_ID",
          "id": medicalId,
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            child: Column(
              children: [
                AtamanHeader(
                  height: 280, // Tighter header
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20), // Removed extra top space
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_getGreeting()},",
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                                ),
                                Text(
                                  userName,
                                  style: AppTextStyles.h2.copyWith(color: Colors.white, height: 1.1),
                                ),
                              ],
                            ),
                            _buildNotificationIcon(context),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDigitalIdCard(medicalId, qrData, state),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SmartTriageCard(
                        onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.triage),
                      ),
                      const SizedBox(height: AppSizes.p20),
                      Text("Quick Services", style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: AppSizes.p8),
                      AtamanServiceGrid(
                        services: const [
                          {'title': 'Medicine Access', 'icon': Icons.medical_services_rounded, 'color': Color(0xFF6A1B9A)},
                          {'title': 'Health Alerts', 'icon': Icons.warning_amber_rounded, 'color': Color(0xFFF57C00)},
                          {'title': 'Reproductive', 'icon': Icons.favorite_outline_rounded, 'color': Color(0xFFAD1457)},
                          {'title': 'Vaccines', 'icon': Icons.vaccines_rounded, 'color': Color(0xFF1976D2)},
                        ],
                        onServiceTap: (index) {
                          if (index == 0) Navigator.of(context).pushNamed(AppRoutes.medicineAccess);
                          else if (index == 1) Navigator.of(context).pushNamed(AppRoutes.healthAlerts);
                          else if (index == 2) Navigator.of(context).pushNamed(AppRoutes.reproductiveHealth);
                          else if (index == 3) Navigator.of(context).pushNamed(AppRoutes.vaccination);
                        },
                      ),
                      const SizedBox(height: AppSizes.p24),
                      EmergencyHelpCard(
                        onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.emergency),
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

  Widget _buildDigitalIdCard(String medicalId, String qrData, AuthState state) {
    return GestureDetector(
      onTap: () {
        if (state is Authenticated && state.profile != null) {
          Navigator.of(context).pushNamed(AppRoutes.medicalId, arguments: state.profile);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 65.0,
                gapless: false,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "DIGITAL MEDICAL ID",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    medicalId,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'Courier',
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Scan to share health records.",
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
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
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.notifications),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.p8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
