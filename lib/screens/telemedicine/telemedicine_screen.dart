import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/telemedicine/prescription_cubit.dart';
import '../../logic/telemedicine/prescription_state.dart';
import '../../widgets/ataman_simple_header.dart';
import '../../widgets/ataman_service_grid.dart';
import '../../widgets/telemedicine/ataman_konsulta_card.dart';
import '../../widgets/telemedicine/ataman_prescription_card.dart';

//skeleton only
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
      context.read<PrescriptionCubit>().startWatchingPrescriptions(authState.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AtamanSimpleHeader(
            height: 115,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  "Tele-Ataman",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<PrescriptionCubit, PrescriptionState>(
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  children: [
                    AtamanKonsultaCard(
                      title: "PhilHealth Konsulta",
                      subtitle: "Free video consults for minor cases.",
                      nextAvailable: "Dr. Santos (3m wait)",
                      onJoinTap: () {
                        // TODO: Logic to join video call
                      },
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
                        // TODO: Handle Telemed Service Navigation
                      },
                    ),
                    
                    const SizedBox(height: AppSizes.p32),
                    
                    Text(
                      "Digital Prescriptions",
                      style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSizes.p16),

                    if (state is PrescriptionLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state is PrescriptionError)
                      Center(child: Text(state.message))
                    else if (state is PrescriptionLoaded)
                      if (state.prescriptions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No active prescriptions found."),
                        )
                      else
                        ...state.prescriptions.map((prescription) => AtamanPrescriptionCard(
                          prescription: prescription,
                          onTap: () {
                            // TODO: Show prescription details/QR
                          },
                        ))
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
