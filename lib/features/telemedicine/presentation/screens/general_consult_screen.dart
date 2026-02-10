import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/telemedicine_cubit.dart';
import 'package:dotted_border/dotted_border.dart';
import '../widgets/telemed_booking_sheet.dart';

class GeneralConsultScreen extends StatefulWidget {
  const GeneralConsultScreen({super.key});

  @override
  State<GeneralConsultScreen> createState() => _GeneralConsultScreenState();
}

class _GeneralConsultScreenState extends State<GeneralConsultScreen> {
  final Set<String> _selectedSymptoms = {};
  final TextEditingController _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Professional approach: Cubit handles the data fetching
    context.read<TelemedicineCubit>().loadSymptoms('general');
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "General Consult",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TelemedicineCubit, TelemedicineState>(
              builder: (context, state) {
                String? doctorId;
                List<String> symptoms = [];

                if (state is TelemedicineLoaded) {
                  symptoms = state.symptoms;
                  if (state.doctors.isNotEmpty) {
                    doctorId = state.doctors.first.id;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildDoctorBanner(state),
                    const SizedBox(height: 32),
                    const Text("What are you feeling?",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text("Select all that apply.",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 16),
                    
                    if (state is TelemedicineLoading && symptoms.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (symptoms.isEmpty)
                      const Text("No symptoms available for selection.", style: TextStyle(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: symptoms.map((name) {
                          final isSelected = _selectedSymptoms.contains(name);
                          return ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) _selectedSymptoms.add(name);
                                else _selectedSymptoms.remove(name);
                              });
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                            ),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      
                    const SizedBox(height: 32),
                    const Text("Additional Details",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _detailsController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Describe your condition further...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AtamanButton(
                      text: "Schedule Consultation",
                      onPressed: doctorId == null
                          ? null
                          : () => _handleProceed(context, doctorId!, state),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorBanner(TelemedicineState state) {
    bool isOnline = false;
    if (state is TelemedicineLoaded) {
      isOnline = state.doctors.any((d) => d.isOnline);
    }

    return DottedBorder(
      color: AppColors.primary.withOpacity(0.5),
      strokeWidth: 1,
      dashPattern: const [6, 3],
      borderType: BorderType.RRect,
      radius: const Radius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? "Doctors are Online" : "Doctors Currently Offline",
                    style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Schedule a pre-prepared session now",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProceed(BuildContext context, String doctorId, TelemedicineState state) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated || state is! TelemedicineLoaded) return;

    final doctor = state.doctors.firstWhere((d) => d.id == doctorId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TelemedBookingSheet(
        doctor: doctor,
        userId: authState.user.id,
      ),
    );
  }
}
