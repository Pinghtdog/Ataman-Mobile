import 'package:flutter/material.dart';

class AtamanLogoFull extends StatelessWidget {
  final double height;

  const AtamanLogoFull({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/icon.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Asset Error: $error");
        return Icon(
          Icons.medical_services_rounded,
          size: height,
          color: Theme.of(context).primaryColor,
        );
      },
    );
  }
}
