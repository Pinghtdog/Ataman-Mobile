import 'package:ataman/constants/constants.dart';
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
// import 'package:ataman/screens/booking_screen.dart';
// import 'package:ataman/screens/telemedicine_screen.dart';
// import 'package:ataman/screens/profile_screen.dart';

class AtamanBaseScreen extends StatefulWidget {
  const AtamanBaseScreen({super.key});

  @override
  State<AtamanBaseScreen> createState() => _AtamanBaseScreenState();
}

class _AtamanBaseScreenState extends State<AtamanBaseScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text("Booking Screen")),
    const Center(child: Text("Telemedicine Screen")),
    const Center(child: Text("Profile Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: Container(
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
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
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
    );
  }
}
