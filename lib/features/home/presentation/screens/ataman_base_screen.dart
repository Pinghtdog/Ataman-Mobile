import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/network_utils.dart';
import '../../../../core/widgets/widgets.dart';

import '../../../booking/presentation/screens/booking_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../telemedicine/presentation/screens/telemedicine_screen.dart';
import 'home_screen.dart';

class AtamanBaseScreen extends StatefulWidget {
  final int initialIndex;
  const AtamanBaseScreen({super.key, this.initialIndex = 0});

  static _AtamanBaseScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AtamanBaseScreenState>();

  @override
  State<AtamanBaseScreen> createState() => _AtamanBaseScreenState();
}

class _AtamanBaseScreenState extends State<AtamanBaseScreen> {
  late int _currentIndex;
  bool _isNavbarVisible = true;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingScreen(),
    const TelemedicineScreen(),
    const ProfileScreen(),
  ];

  void setNavbarVisibility(bool visible) {
    if (_isNavbarVisible != visible) {
      setState(() {
        _isNavbarVisible = visible;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NetworkUtils.initialize(context);
    });
  }

  @override
  void dispose() {
    NetworkUtils.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isNavbarVisible ? kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom : 0,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary.withOpacity(0.5),
              showUnselectedLabels: true,
              selectedLabelStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  activeIcon: Icon(Icons.home_filled),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_rounded),
                  label: "Booking",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.video_camera_front_rounded),
                  label: "Telemed",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
