import 'package:flutter/material.dart';

class TelemedicineService {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String iconName;
  final Color bgColor;
  final Color iconColor;

  TelemedicineService({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.bgColor,
    required this.iconColor,
  });

  factory TelemedicineService.fromMap(Map<String, dynamic> map) {
    return TelemedicineService(
      id: map['id'],
      category: map['category'] ?? 'general',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      iconName: map['icon_name'] ?? 'help_outline',
      bgColor: Color(int.parse(map['bg_color'] ?? '0xFFF5F5F5')),
      iconColor: Color(int.parse(map['icon_color'] ?? '0xFF000000')),
    );
  }
}
