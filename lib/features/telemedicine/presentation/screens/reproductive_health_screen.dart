import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/telemedicine_cubit.dart';
import 'video_call_screen.dart';

class ReproductiveHealthScreen extends StatefulWidget {
  const ReproductiveHealthScreen({super.key});

  @override
  State<ReproductiveHealthScreen> createState() => _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen> {
  String _selectedService = "Family Planning";
  bool _isVideoMode = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Family Planning',
      'subtitle': 'Pills, Implants, IUD',
      'icon': Icons.more_horiz_rounded,
      'color': const Color(0xFFFFD1D1),
      'iconColor': Colors.pink,
    },
    {
      'title': 'Sexual Health',
      'subtitle': 'STI/HIV, Screening',
      'icon': Icons.add_rounded,
      'color': const Color(0xFFE1BEE7),
      'iconColor': Colors.purple,
    },
    {
      'title': 'Maternal Care',
      'subtitle': 'Prenatal, Postnatal',
      'icon': Icons.circle_outlined,
      'color': const Color(0xFFE0F2F1),
      'iconColor': Colors.teal,
    },
    {
      'title': 'Counseling',
      'subtitle': 'Guidance & Support',
      'icon': Icons.drag_handle_rounded,
      'color': const Color(0xFFFFF9C4),
      'iconColor': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanSimpleHeader(
            height: 120,
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Reproductive Health",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TelemedicineCubit, TelemedicineState>(
              builder: (context, state) {
                String? doctorId;
                if (state is TelemedicineDoctorsLoaded && state.doctors.isNotEmpty) {
                  final onlineDoctor = state.doctors.where((d) => d.isOnline).firstOrNull;
                  doctorId = onlineDoctor?.id;
                }

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Confidentiality Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3238),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Confidential & Safe",
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Your records are encrypted.\nNo judgment, just care.",
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Text("What do you need help with?", style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontSize: 18)),
                    const SizedBox(height: 24),
                    
                    // Services Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        final isSelected = _selectedService == service['title'];
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedService = service['title']),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey.shade100,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: service['color'], shape: BoxShape.circle),
                                  child: Icon(service['icon'], color: service['iconColor'], size: 24),
                                ),
                                Text(
                                  service['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Consultation Mode
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Consultation Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              children: [
                                _buildModeToggle("Video", _isVideoMode, () => setState(() => _isVideoMode = true)),
                                _buildModeToggle("Audio", !_isVideoMode, () => setState(() => _isVideoMode = false)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    AtamanButton(
                      text: "Connect with Specialist",
                      isLoading: _isLoading,
                      onPressed: doctorId == null ? null : () => _handleConnect(doctorId!),
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

  Widget _buildModeToggle(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2D3238) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _handleConnect(String doctorId) async {
    final status = await [Permission.camera, Permission.microphone].request();
    if (_isVideoMode && (!status[Permission.camera]!.isGranted || !status[Permission.microphone]!.isGranted)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permissions required for call")));
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
            'service_type': 'reproductive',
            'sub_service': _selectedService,
            'consultation_mode': _isVideoMode ? 'video' : 'audio',
          },
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallScreen(
                callId: callId,
                userId: authState.user!.id,
                isCaller: true,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to connect: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
