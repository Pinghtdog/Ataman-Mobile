import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/telemedicine_cubit.dart';
import '../../data/models/doctor_model.dart';
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
  String? _selectedDoctorId;

  @override
  void initState() {
    super.initState();
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
                List<String> symptoms = [];
                List<DoctorModel> doctors = [];

                if (state is TelemedicineLoaded) {
                  symptoms = state.symptoms;
                  doctors = state.doctors;
                  // Auto-select first doctor if none selected and list is not empty
                  if (_selectedDoctorId == null && doctors.isNotEmpty) {
                    _selectedDoctorId = doctors.first.id;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text("Select Doctor",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    _buildDoctorDropdown(doctors),
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
                      onPressed: _selectedDoctorId == null
                          ? null
                          : () => _handleProceed(context, _selectedDoctorId!, state),
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

  Widget _buildDoctorDropdown(List<DoctorModel> doctors) {
    if (doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text("No doctors available", style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDoctorId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          hint: const Text("Choose a doctor"),
          items: doctors.map((doctor) {
            return DropdownMenuItem<String>(
              value: doctor.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(doctor.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(doctor.specialty ?? "General Practice", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (doctor.isOnline)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedDoctorId = newValue;
            });
          },
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
