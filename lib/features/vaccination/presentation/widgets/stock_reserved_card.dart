import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class StockReservedCard extends StatelessWidget {
  const StockReservedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, style: BorderStyle.solid, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle, color: Colors.green, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(AppStrings.stockReservedForBooking, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(AppStrings.concepcionPequenaBHC, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
