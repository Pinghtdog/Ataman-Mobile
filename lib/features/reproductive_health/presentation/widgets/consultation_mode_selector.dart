import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class ConsultationModeSelector extends StatelessWidget {
  const ConsultationModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.consultationMode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ToggleButtons(
              isSelected: const [false, true],
              onPressed: (index) {},
              borderRadius: BorderRadius.circular(20),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.video)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppStrings.audio)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
