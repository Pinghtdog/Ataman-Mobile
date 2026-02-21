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
///
/// This screen provides users with access to:
/// 1. **Live & Upcoming Sessions**: Real-time status of scheduled video consultations.
/// 2. **Doctor Discovery**: A list of available medical specialists for booking or immediate consult.
/// 3. **Service Specialized Care**: Direct access to General and Reproductive health consultations.
/// 4. **Digital Prescriptions**: A history of prescriptions issued during telemedicine sessions.
///
/// It utilizes [TelemedicineCubit] for session and doctor management, and [PrescriptionCubit] 
/// for real-time tracking of medical prescriptions.
class TelemedicineScreen extends StatefulWidget {
  const TelemedicineScreen({super.key});

  @override
  State<TelemedicineScreen> createState() => _TelemedicineScreenState();
}

class _TelemedicineScreenState extends State<TelemedicineScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize real-time listeners for prescriptions, doctors, and active sessions.
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<PrescriptionCubit>().startWatchingPrescriptions(authState.user.id);
      final telemedCubit = context.read<TelemedicineCubit>();
      telemedCubit.startWatchingDoctors();
      telemedCubit.startWatchingSessions(authState.user.id);
    }
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
                      return ListView(
                        padding: const EdgeInsets.all(AppSizes.p24),
                        children: [
                          // 1. ACTIVE SESSION CARD (REAL DATA)
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

  /// Builds the section for active or upcoming consultations.
  /// 
  /// Logic:
  /// - Finds the doctor's details associated with the session.
  /// - Determines if the session is "Live" or "Upcoming" based on its status and time.
  /// - Enables the "Join" button only if the status is active or within a 10-minute window of start.
  Widget _buildActiveSessionSection(BuildContext context, TelemedicineLoaded state, String userId, String userName) {
    final session = state.activeSessions.first;
    final doctorId = session['doctor_id'];
    
    // Find doctor info from the loaded doctors list
    final doctor = state.doctors.cast<DoctorModel?>().firstWhere(
      (d) => d?.id == doctorId,
      orElse: () => null,
    );

    final String doctorName = doctor?.fullName ?? "Doctor";
    final String specialty = doctor?.specialty ?? "Medical Specialist";
    final DateTime? scheduledTime = session['scheduled_time'] != null 
        ? DateTime.parse(session['scheduled_time']) 
        : null;
    
    String timeStr = "Now";
    bool canJoin = true;

    if (scheduledTime != null) {
      final now = DateTime.now();
      final difference = scheduledTime.difference(now);
      
      // Allow joining 10 minutes before OR if status is active
      canJoin = session['status'] == 'active' || difference.inMinutes <= 10;

      if (scheduledTime.day == now.day) {
        timeStr = "Today, ${DateFormat('hh:mm a').format(scheduledTime)}";
      } else {
        timeStr = DateFormat('MMM dd, hh:mm a').format(scheduledTime);
      }

      if (!canJoin) {
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

  /// Placeholder widget displayed when there are no active telemedicine sessions.
  Widget _buildNoActiveSessionPlaceholder() {
    return AtamanKonsultaCard(
      title: "Tele-Consult",
      subtitle: "Speak with a doctor from home",
      nextAvailable: "Book a slot below",
      onJoinTap: null, // Join disabled if no session
    );
  }
}
