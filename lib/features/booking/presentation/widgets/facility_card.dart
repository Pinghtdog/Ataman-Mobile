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
    // Determine status based on BOTH explicit status and queue count
    final bool isActuallyCongested = facility.status == FacilityStatus.congested || facility.queueCount >= 20;
    final bool isClosed = facility.status == FacilityStatus.closed;
    final bool isAvailable = !isClosed && !isActuallyCongested;

    Color statusColor = AppColors.danger;
    Color statusBg = AppColors.danger.withOpacity(0.1);
    String statusText = "High Congestion";
    IconData statusIcon = Icons.warning_rounded;

    if (isClosed) {
      statusColor = AppColors.textSecondary;
      statusBg = AppColors.textSecondary.withOpacity(0.1);
      statusText = "Closed";
      statusIcon = Icons.block;
    } else if (isAvailable) {
      statusColor = AppColors.success;
      statusBg = AppColors.success.withOpacity(0.1);
      statusText = "Available for Booking";
      statusIcon = Icons.check_circle;
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

                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                            Flexible(
                              child: Text(
                                statusText,
                                style: AppTextStyles.caption.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (facility.status != FacilityStatus.closed)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline, size: 14, color: AppColors.primary),
                              const SizedBox(width: AppSizes.p8),
                              Flexible(
                                child: Text(
                                  "${facility.queueCount} in Queue",
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppSizes.p16),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: AppSizes.p16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(
                      label: "Est. Wait",
                      value: facility.estimatedWaitTime,
                      icon: Icons.timer_outlined,
                      color: AppColors.info,
                    ),
                    _buildVerticalDivider(),
                    _buildStat(
                      label: "Queue",
                      value: facility.queueStatus,
                      icon: Icons.analytics_outlined,
                      color: _getQueueColor(facility.queueStatus),
                      isText: true,
                    ),
                    _buildVerticalDivider(),
                    _buildStat(
                      label: "Meds",
                      value: facility.medsStatus,
                      icon: Icons.medication_liquid_outlined,
                      color: Colors.purple,
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

  Color _getQueueColor(String status) {
    switch (status) {
      case 'Light': return AppColors.success;
      case 'Moderate': return Colors.orange;
      case 'Busy': return AppColors.danger;
      default: return AppColors.textSecondary;
    }
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
      margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced margin
    );
  }
}
