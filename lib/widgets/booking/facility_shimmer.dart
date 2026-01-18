import 'package:flutter/material.dart';
import '../../constants/constants.dart';
import '../ataman_shimmer.dart';

class FacilityShimmer extends StatelessWidget {const FacilityShimmer({super.key});

@override
Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(bottom: AppSizes.p16),
    padding: const EdgeInsets.all(AppSizes.p16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AtamanShimmer.rounded(width: 180, height: 20),
            AtamanShimmer.rounded(
                width: 50,
                height: 20,
                shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSmall))
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        const AtamanShimmer.rounded(width: 140, height: 12),
        const SizedBox(height: AppSizes.p20),

        AtamanShimmer.rounded(
            width: 120,
            height: 24,
            shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSmall))
        ),

        const SizedBox(height: AppSizes.p20),
        const Divider(height: 1),
        const SizedBox(height: AppSizes.p20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AtamanShimmer.rounded(width: 70, height: 35),
            _buildDivider(),
            const AtamanShimmer.rounded(width: 70, height: 35),
            _buildDivider(),
            const AtamanShimmer.rounded(width: 70, height: 35),
          ],
        ),
      ],
    ),
  );
}

Widget _buildDivider() => Container(height: 24, width: 1, color: Colors.grey[200]);
}