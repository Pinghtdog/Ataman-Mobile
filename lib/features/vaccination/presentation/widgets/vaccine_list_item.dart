import 'package:flutter/material.dart';
import 'package:ataman/core/constants/app_strings.dart';

enum StockStatus { inStock, limited, noStock }

class VaccineListItem extends StatelessWidget {
  final String abbr;
  final String name;
  final String description;
  final StockStatus stockStatus;

  const VaccineListItem({
    super.key,
    required this.abbr,
    required this.name,
    required this.description,
    required this.stockStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getVaccineColor(abbr).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                abbr,
                style: TextStyle(
                  color: _getVaccineColor(abbr),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          _buildStockBadge(stockStatus),
        ],
      ),
    );
  }

  Widget _buildStockBadge(StockStatus status) {
    String text;
    Color bgColor;
    Color textColor;

    switch (status) {
      case StockStatus.inStock:
        text = AppStrings.inStock;
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        break;
      case StockStatus.limited:
        text = AppStrings.limited;
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        break;
      case StockStatus.noStock:
        text = AppStrings.noStock;
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Color _getVaccineColor(String abbr) {
    switch (abbr) {
      case 'FLU':
        return Colors.purple;
      case 'PNE':
        return Colors.blue;
      case 'RAB':
        return Colors.red;
      case 'TET':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
