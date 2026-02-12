import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AtamanButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final Color? textColor;
  final double? width;
  final IconData? icon;

  const AtamanButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.textColor,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveWidth = width ?? double.infinity;

    Widget buildContent(Color contentColor) {
      if (isLoading) {
        return SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: contentColor,
          ),
        );
      }

      if (icon != null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: contentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: contentColor,
                fontSize: 16,
                fontWeight: isOutlined ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ],
        );
      }

      return Text(
        text,
        style: TextStyle(
          color: contentColor,
          fontSize: 16,
          fontWeight: isOutlined ? FontWeight.normal : FontWeight.bold,
        ),
      );
    }

    if (isOutlined) {
      final Color borderAndTextColor = textColor ?? color ?? AppColors.primary;
      return SizedBox(
        width: effectiveWidth,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color ?? AppColors.primary),
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: buildContent(borderAndTextColor),
        ),
      );
    }

    final Color buttonTextColor = textColor ?? Colors.white;
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
        child: buildContent(buttonTextColor),
      ),
    );
  }
}
