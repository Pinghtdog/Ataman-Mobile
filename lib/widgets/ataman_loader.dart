import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AtamanLoader extends StatelessWidget {
  final bool isOpen;

  const AtamanLoader({super.key, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}