import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/prescription_cubit.dart';
import '../../logic/prescription_state.dart';
import '../../logic/telemedicine_cubit.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/telemed_doctor_section.dart';
import '../widgets/telemed_prescription_section.dart';
import '../widgets/prescription_details_modal.dart';

class TelemedicineScreen extends StatefulWidget {
  const TelemedicineScreen({super.key});

  @override
  State<TelemedicineScreen> createState() => _TelemedicineScreenState();
}

class _TelemedicineScreenState extends State<TelemedicineScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<PrescriptionCubit>().startWatchingPrescriptions(authState.user.id);
      context.read<TelemedicineCubit>().startWatchingDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
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
}
