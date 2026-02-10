import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
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
  bool _isVideoMode = true;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<TelemedicineCubit>().startWatchingDoctors();
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

                if (state is TelemedicineLoaded) {
                  final doctors = state.doctors;
                  final List<TelemedicineService> services = [
                    TelemedicineService(
                      id: '1',
                      title: 'Family Planning',
                      category: 'reproductive',
                      subtitle: 'Planning and contraception',
                      iconName: 'family_restroom',
                      bgColor: const Color(0xFFFCE4EC),
                      iconColor: const Color(0xFFAD1457),
                    ),
                    TelemedicineService(
                      id: '2',
                      title: 'Maternal Care',
                      category: 'reproductive',
                      subtitle: 'Pregnancy and postnatal support',
                      iconName: 'pregnant_woman',
                      bgColor: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF7B1FA2),
                    ),
                    TelemedicineService(
                      id: '3',
                      title: 'Sexual Health',
                      category: 'reproductive',
                      subtitle: 'STI and sexual wellness',
                      iconName: 'health_and_safety',
                      bgColor: const Color(0xFFE1F5FE),
                      iconColor: const Color(0xFF0288D1),
                    ),
                    TelemedicineService(
                      id: '4',
                      title: 'Counseling',
                      category: 'reproductive',
                      subtitle: 'Emotional and mental support',
                      iconName: 'psychology',
                      bgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF388E3C),
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
                        text: "Schedule Consultation",
                        isLoading: _isLoading,
                        onPressed: doctors.isEmpty
                            ? null
                            : () => _handleSchedule(context, doctors.first),
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
                  BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded,
                  color: AppColors.primary, size: 24),
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
}
