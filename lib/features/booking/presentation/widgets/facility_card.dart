import 'package:flutter/material.dart';
import '../../../facility/data/models/facility_model.dart';
import '../../../../core/constants/constants.dart';

class FacilityCard extends StatelessWidget {
  final Facility facility;
  final VoidCallback onTap;

  const FacilityCard({
    super.key,
    required this.facility,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClosed = facility.status == FacilityStatus.closed;
    final bool isStale = facility.isStale;
    final bool isDiversion = facility.isDiversionActive;

    Color statusColor = AppColors.success;
    Color statusBg = AppColors.success.withOpacity(0.1);
    String statusText = facility.availabilityStatus;
    IconData statusIcon = Icons.calendar_today_rounded;
    
    if (isClosed) {
      statusColor = AppColors.textSecondary;
      statusBg = AppColors.textSecondary.withOpacity(0.1);
      statusIcon = Icons.block;
    } else if (isDiversion) {
      statusColor = AppColors.danger;
      statusBg = AppColors.danger.withOpacity(0.1);
      statusText = "DIVERSION ACTIVE (Seek Alternatives)";
      statusIcon = Icons.alt_route_rounded;
    } else if (facility.status == FacilityStatus.congested) {
      statusColor = AppColors.warning;
      statusBg = AppColors.warning.withOpacity(0.1);
      statusIcon = Icons.groups_rounded;
    } else if (isStale) {
      statusColor = AppColors.warning;
      statusBg = AppColors.warning.withOpacity(0.1);
      statusIcon = Icons.timer_off_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        child: InkWell(
          onTap: isClosed ? null : onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facility.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.p4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: AppSizes.p4),
                              Expanded(
                                child: Text(
                                  facility.address,
                                  style: AppTextStyles.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: AppSizes.p4),
                          Flexible(
                            child: Text(
                              facility.distance,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.p16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: AppSizes.p8),
                      Text(
                        statusText,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.p16),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: AppSizes.p16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(
                      label: "Hours",
                      value: facility.operatingStatus,
                      icon: Icons.access_time_rounded,
                      color: AppColors.info,
                    ),
                    _buildVerticalDivider(),
                    _buildStat(
                      label: "Rating",
                      value: "${facility.rating} (${facility.reviewCount})",
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                      isText: true,
                    ),
                    _buildVerticalDivider(),
                    _buildStat(
                      label: "Service",
                      value: facility.type == FacilityType.hospital ? "Multi-specialty" : "Primary Care",
                      icon: Icons.medical_services_outlined,
                      color: AppColors.primary,
                      isText: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isText = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSizes.p4),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isText ? color : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
