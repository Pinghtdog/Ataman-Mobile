import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/telemedicine_cubit.dart';
import 'package:dotted_border/dotted_border.dart';
import 'video_call_screen.dart';

class GeneralConsultScreen extends StatefulWidget {
  const GeneralConsultScreen({super.key});

  @override
  State<GeneralConsultScreen> createState() => _GeneralConsultScreenState();
}

class _GeneralConsultScreenState extends State<GeneralConsultScreen> {
  final List<String> _symptoms = [
    "Fever",
    "Cough",
    "Headache",
    "Sore Throat",
    "Other"
  ];
  final Set<String> _selectedSymptoms = {};
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

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
                int waitTime = 5;
                String? doctorId;

                if (state is TelemedicineDoctorsLoaded &&
                    state.doctors.isNotEmpty) {
                  final onlineDoctor =
                      state.doctors.where((d) => d.isOnline).firstOrNull;
                  if (onlineDoctor != null) {
                    waitTime = onlineDoctor.currentWaitMinutes;
                    doctorId = onlineDoctor.id;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    DottedBorder(
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
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Next Available GP",
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Est. Wait Time: $waitTime-${waitTime + 2} mins",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text("What are you feeling?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text("Select all that apply.",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symptoms.map((symptom) {
                        final isSelected = _selectedSymptoms.contains(symptom);
                        return ChoiceChip(
                          label: Text(symptom),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected)
                                _selectedSymptoms.add(symptom);
                              else
                                _selectedSymptoms.remove(symptom);
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Text("Additional Details",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _detailsController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Temp is 38.5C since last night...",
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DottedBorder(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                      dashPattern: const [6, 3],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                color: AppColors.primary.withOpacity(0.8),
                                size: 24),
                            const SizedBox(width: 8),
                            Text("Add Photo (Optional)",
                                style: TextStyle(
                                    color: AppColors.primary.withOpacity(0.8),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AtamanButton(
                      text: "Join Queue ($waitTime min)",
                      isLoading: _isLoading,
                      onPressed: doctorId == null
                          ? null
                          : () => _handleJoinQueue(doctorId!),
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

  Future<void> _handleJoinQueue(String doctorId) async {
    final status = await [Permission.camera, Permission.microphone].request();
    if (!status[Permission.camera]!.isGranted ||
        !status[Permission.microphone]!.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permissions required for call")));
      }
      return;
    }

    setState(() => _isLoading = true);
    final authState = context.read<AuthCubit>().state;

    if (authState is Authenticated) {
      try {
        final callId = await context.read<TelemedicineCubit>().initiateCall(
          authState.user!.id,
          doctorId,
          metadata: {
            'service_type': 'general',
            'symptoms': _selectedSymptoms.toList(),
            'details': _detailsController.text,
          },
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallScreen(
                callId: callId,
                userId: authState.user!.id,
                userName: authState.user!.userMetadata?['full_name'] ?? 'Patient',
                isCaller: true,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to join queue: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
