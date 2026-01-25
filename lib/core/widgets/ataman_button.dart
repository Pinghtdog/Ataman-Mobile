import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AtamanButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;

  const AtamanButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveWidth = width ?? double.infinity;

    if (isOutlined) {
      return SizedBox(
        width: effectiveWidth,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color ?? AppColors.primary),
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : Text(text, style: TextStyle(color: color ?? AppColors.primary, fontSize: 16)),
        ),
      );
    }

    return SizedBox(
      width: effectiveWidth,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20, 
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : Text(
                text, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.bold
                )
              ),
      ),
    );
  }
}
