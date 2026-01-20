import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class MyNagaAuthDialog extends StatelessWidget {
  const MyNagaAuthDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShield(
                    color: const Color(0xFF1976D2),
                    icon: Icons.location_city_rounded
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.sync_alt, color: Colors.grey, size: 24),
                ),

                _buildShield(
                    color: AppColors.primary,
                    icon: Icons.health_and_safety_rounded
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Connect to Ataman",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Ataman requests access to your MyNaga Citizen Profile.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              "THIS WILL SHARE:",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.0
              ),
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(Icons.badge_outlined, "Full Name & Birthdate"),
            _buildPermissionItem(Icons.home_outlined, "Home Address (Barangay)"),
            _buildPermissionItem(Icons.description_outlined, "CSWD Indigency Status"),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // context.read<AuthCubit>().connectMyNaga();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Authorize", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShield({required Color color, required IconData icon}) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00695C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
            ),
          ),
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
    );
  }
}