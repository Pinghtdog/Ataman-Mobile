import 'package:ataman/core/constants/app_strings.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class AddPhotoButton extends StatelessWidget {
  const AddPhotoButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      color: Colors.grey[400]!,
      strokeWidth: 1,
      dashPattern: const [4, 4],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(AppStrings.addPhotoOptional, style: TextStyle(color: theme.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}
