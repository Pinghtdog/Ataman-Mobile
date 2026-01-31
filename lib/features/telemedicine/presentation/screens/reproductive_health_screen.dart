import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/models/telemedicine_service_model.dart';
import '../../logic/telemedicine_cubit.dart';
import 'video_call_screen.dart';

class ReproductiveHealthScreen extends StatefulWidget {
  const ReproductiveHealthScreen({super.key});

  @override
  State<ReproductiveHealthScreen> createState() =>
      _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen> {
  String? _selectedServiceTitle;
  bool _isVideoMode = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load services for this specific category
    context.read<TelemedicineCubit>().loadServicesAndDoctors('reproductive');
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
                  AppStrings.reproductiveHealth,
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
                if (state is TelemedicineLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TelemedicineError) {
                  return Center(child: Text(state.message));
                }

                if (state is TelemedicineDataLoaded) {
                  final services = state.services;
                  final doctors = state.doctors;

                  // Auto-select first service if none selected
                  if (_selectedServiceTitle == null && services.isNotEmpty) {
                    _selectedServiceTitle = services.first.title;
                  }

                  final onlineDoctor =
                      doctors.where((d) => d.isOnline).firstOrNull;
                  final doctorId = onlineDoctor?.id;

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildConfidentialityBanner(),
                      const SizedBox(height: 32),
                      Text(AppStrings.whatDoYouNeedHelpWith,
                          style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimary, fontSize: 18)),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          final isSelected =
                              _selectedServiceTitle == service.title;

                          return _buildServiceCard(service, isSelected);
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildConsultationModeSelector(),
                      const SizedBox(height: 32),
                      AtamanButton(
                        text: AppStrings.connectWithSpecialist,
                        isLoading: _isLoading,
                        onPressed: doctorId == null
                            ? null
                            : () => _handleConnect(doctorId),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(TelemedicineService service, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedServiceTitle = service.title),
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
              decoration:
                  BoxDecoration(color: service.bgColor, shape: BoxShape.circle),
              child: Icon(_getIconData(service.iconName),
                  color: service.iconColor, size: 24),
            ),
            Text(
              service.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'more_horiz':
        return Icons.more_horiz_rounded;
      case 'add':
        return Icons.add_rounded;
      case 'circle_outlined':
        return Icons.circle_outlined;
      case 'drag_handle':
        return Icons.drag_handle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildConfidentialityBanner() {
    return Container(
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
            child:
                const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.confidentialAndSafe,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.noJudgmentJustCare,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              AppStrings.consultationMode,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeToggle(AppStrings.video, _isVideoMode,
                    () => setState(() => _isVideoMode = true)),
                _buildModeToggle(AppStrings.audio, !_isVideoMode,
                    () => setState(() => _isVideoMode = false)),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2D3238) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _handleConnect(String doctorId) async {
    final status = await [Permission.camera, Permission.microphone].request();
    if (_isVideoMode &&
        (!status[Permission.camera]!.isGranted ||
            !status[Permission.microphone]!.isGranted)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permissions required for call")));
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
            'sub_service': _selectedServiceTitle,
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
                userName: authState.user!.fullName ?? 'Patient',
                isCaller: true,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to connect: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
