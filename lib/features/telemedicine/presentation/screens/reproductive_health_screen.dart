import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/telemedicine_service_model.dart';
import '../../logic/telemedicine_cubit.dart';
import '../widgets/telemed_booking_sheet.dart';

class ReproductiveHealthScreen extends StatefulWidget {
  const ReproductiveHealthScreen({super.key});

  @override
  State<ReproductiveHealthScreen> createState() =>
      _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen> {
  String? _selectedServiceTitle;
  String? _selectedDoctorId;
  bool _isVideoMode = true;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<TelemedicineCubit>().startWatchingDoctors();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'family_restroom':
        return Icons.family_restroom_rounded;
      case 'pregnant_woman':
        return Icons.pregnant_woman_rounded;
      case 'health_and_safety':
        return Icons.health_and_safety_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      default:
        return Icons.favorite_rounded;
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

                List<DoctorModel> doctors = [];
                if (state is TelemedicineLoaded) {
                  doctors = state.doctors;
                  if (_selectedDoctorId == null && doctors.isNotEmpty) {
                    _selectedDoctorId = doctors.first.id;
                  }

                  final List<TelemedicineService> services = [
                    TelemedicineService(
                      id: '1',
                      title: 'Family Planning',
                      category: 'reproductive',
                      subtitle: 'Planning & Contraception',
                      iconName: 'family_restroom',
                      bgColor: const Color(0xFFFFF1F1),
                      iconColor: const Color(0xFFE91E63),
                    ),
                    TelemedicineService(
                      id: '2',
                      title: 'Maternal Care',
                      category: 'reproductive',
                      subtitle: 'Pregnancy Support',
                      iconName: 'pregnant_woman',
                      bgColor: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF9C27B0),
                    ),
                    TelemedicineService(
                      id: '3',
                      title: 'Sexual Health',
                      category: 'reproductive',
                      subtitle: 'Wellness & STIs',
                      iconName: 'health_and_safety',
                      bgColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF2196F3),
                    ),
                    TelemedicineService(
                      id: '4',
                      title: 'Counseling',
                      category: 'reproductive',
                      subtitle: 'Mental Support',
                      iconName: 'psychology',
                      bgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF4CAF50),
                    ),
                  ];

                  if (_selectedServiceTitle == null && services.isNotEmpty) {
                    _selectedServiceTitle = services.first.title;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildConfidentialityBanner(),
                      const SizedBox(height: 32),
                      _buildSectionHeader("Select Specialist"),
                      const SizedBox(height: 16),
                      _buildDoctorSelector(doctors),
                      const SizedBox(height: 32),
                      _buildSectionHeader(AppStrings.whatDoYouNeedHelpWith),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
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
                        text: "Schedule Consultation",
                        isLoading: _isLoading,
                        onPressed: _selectedDoctorId == null
                            ? null
                            : () {
                                final selectedDoctor = doctors.firstWhere((d) => d.id == _selectedDoctorId);
                                _handleSchedule(context, selectedDoctor);
                              },
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildDoctorSelector(List<DoctorModel> doctors) {
    if (doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("No specialists available", style: TextStyle(color: Colors.grey)),
      );
    }

    final selectedDoctor = doctors.firstWhere((d) => d.id == _selectedDoctorId, orElse: () => doctors.first);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.white),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedDoctorId,
            isExpanded: true,
            icon: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.unfold_more_rounded, color: Colors.grey),
            ),
            items: doctors.map((doctor) {
              return DropdownMenuItem<String>(
                value: doctor.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              doctor.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              doctor.specialty ?? "Specialist",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (doctor.isOnline)
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                    ],
                  ),
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
      ),
    );
  }

  void _handleSchedule(BuildContext context, doctor) {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
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

  Widget _buildServiceCard(TelemedicineService service, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedServiceTitle = service.title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: service.bgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _getIconData(service.iconName),
                color: service.iconColor,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              service.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? AppColors.textPrimary : Colors.grey.shade800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service.subtitle ?? "",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidentialityBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2D3238), const Color(0xFF1A1D21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "100% Confidential",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                ),
                SizedBox(height: 2),
                Text(
                  "Private and encrypted consultation",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
            child: Text(
              "Consultation Mode",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100)
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeToggle(AppStrings.video, Icons.videocam_rounded, _isVideoMode,
                      () => setState(() => _isVideoMode = true)),
                ),
                Expanded(
                  child: _buildModeToggle(AppStrings.audio, Icons.mic_rounded, !_isVideoMode,
                      () => setState(() => _isVideoMode = false)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(String text, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2D3238) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
