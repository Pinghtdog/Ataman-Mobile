import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/prescription_cubit.dart';
import '../../logic/prescription_state.dart';
import '../../logic/telemedicine_cubit.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/telemed_doctor_section.dart';
import '../widgets/telemed_prescription_section.dart';
import '../widgets/prescription_details_modal.dart';
import '../widgets/ataman_konsulta_card.dart';
import 'video_call_screen.dart';
import '../../data/models/doctor_model.dart';

/// [TelemedicineScreen] (Tele-Ataman) serves as the central hub for virtual medical consultations.
class TelemedicineScreen extends StatefulWidget {
  const TelemedicineScreen({super.key});

  @override
  State<TelemedicineScreen> createState() => _TelemedicineScreenState();
}

class _TelemedicineScreenState extends State<TelemedicineScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<PrescriptionCubit>().startWatchingPrescriptions(authState.user.id);
      final telemedCubit = context.read<TelemedicineCubit>();
      telemedCubit.startWatchingDoctors();
      telemedCubit.startWatchingSessions(authState.user.id);
    }
  }

  Future<void> _handleRefresh() async {
    _loadInitialData();
    // Allow the refresh indicator to be visible for a short duration
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String userName = "User";
    String userId = "";
    if (authState is Authenticated) {
      userName = authState.profile?.fullName ?? "User";
      userId = authState.user.id;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanHeader(
            isSimple: true,
            height: 120,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            child: const SafeArea(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Tele-Ataman",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: MultiBlocListener(
              listeners: [
                BlocListener<TelemedicineCubit, TelemedicineState>(
                  listener: (context, state) {
                    if (state is TelemedicineError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                ),
              ],
              child: BlocBuilder<PrescriptionCubit, PrescriptionState>(
                builder: (context, prescriptionState) {
                  return BlocBuilder<TelemedicineCubit, TelemedicineState>(
                    builder: (context, telemedState) {
                      return RefreshIndicator(
                        onRefresh: _handleRefresh,
                        color: AppColors.primary,
                        child: ListView(
                          padding: const EdgeInsets.all(AppSizes.p24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            if (telemedState is TelemedicineLoaded && telemedState.activeSessions.isNotEmpty)
                              _buildActiveSessionSection(context, telemedState, userId, userName)
                            else if (telemedState is TelemedicineLoaded && telemedState.activeSessions.isEmpty)
                              _buildNoActiveSessionPlaceholder(),
                            
                            const SizedBox(height: AppSizes.p24),
                            
                            TelemedDoctorSection(
                              state: telemedState,
                            ),
                            
                            const SizedBox(height: AppSizes.p32),
                            
                            Text(
                              "Choose Service",
                              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: AppSizes.p16),
                            
                            AtamanServiceGrid(
                              services: const [
                                {
                                  'title': 'General',
                                  'icon': Icons.medical_services_rounded,
                                  'color': AppColors.accent,
                                },
                                {
                                  'title': 'Reproductive',
                                  'icon': Icons.favorite_rounded,
                                  'color': Color(0xFFAD1457),
                                },
                              ],
                              onServiceTap: (index) {
                                if (index == 0) {
                                  Navigator.pushNamed(context, AppRoutes.generalConsult);
                                } else if (index == 1) {
                                  Navigator.pushNamed(context, AppRoutes.reproductiveHealth);
                                }
                              },
                            ),
                            
                            const SizedBox(height: AppSizes.p32),
                            
                            Text(
                              "Digital Prescriptions",
                              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: AppSizes.p16),
      
                            TelemedPrescriptionSection(
                              state: prescriptionState,
                              onPrescriptionTap: (prescription) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => PrescriptionDetailsModal(prescription: prescription),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionSection(BuildContext context, TelemedicineLoaded state, String userId, String userName) {
    final session = state.activeSessions.first;
    final doctorId = session['doctor_id'];
    
    final doctor = state.doctors.cast<DoctorModel?>().firstWhere(
      (d) => d?.id == doctorId,
      orElse: () => null,
    );

    final String doctorName = doctor?.fullName ?? "Doctor";
    final String specialty = doctor?.specialty ?? "Medical Specialist";
    
    // FIX: Parse as Local time to ensure UI matches user's timezone
    final DateTime? scheduledTime = session['scheduled_time'] != null 
        ? DateTime.parse(session['scheduled_time']).toLocal() 
        : null;
    
    String timeStr = "Now";
    bool canJoin = true;

    if (scheduledTime != null) {
      final now = DateTime.now();
      final difference = scheduledTime.difference(now);
      
      // Allow joining 10 minutes before OR if status is active
      canJoin = session['status'] == 'active' || difference.inMinutes <= 10;

      if (scheduledTime.year == now.year && scheduledTime.month == now.month && scheduledTime.day == now.day) {
        timeStr = "Today, ${DateFormat('hh:mm a').format(scheduledTime)}";
      } else {
        timeStr = DateFormat('MMM dd, hh:mm a').format(scheduledTime);
      }

      if (!canJoin && session['status'] != 'active') {
        final joinTime = scheduledTime.subtract(const Duration(minutes: 10));
        timeStr = "Joinable at ${DateFormat('hh:mm a').format(joinTime)}";
      }
    }

    final bool isActive = session['status'] == 'active';

    return AtamanKonsultaCard(
      title: isActive ? "Live Consultation" : "Upcoming Consultation",
      subtitle: "$doctorName • $specialty",
      nextAvailable: timeStr,
      onJoinTap: canJoin ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              callId: session['id'].toString(),
              userId: userId,
              userName: userName,
              isCaller: true,
            ),
          ),
        );
      } : null,
    );
  }

  Widget _buildNoActiveSessionPlaceholder() {
    return AtamanKonsultaCard(
      title: "Tele-Consult",
      subtitle: "Speak with a doctor from home",
      nextAvailable: "Book a slot below",
      onJoinTap: null,
    );
  }
}
