import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/data/model/family_member_model.dart';

class BookingMemberSelector extends StatelessWidget {
  final String userName;
  final List<FamilyMember> familyMembers;
  final dynamic selectedMember;
  final Function(dynamic) onMemberSelected;

  const BookingMemberSelector({
    super.key,
    required this.userName,
    required this.familyMembers,
    required this.selectedMember,
    required this.onMemberSelected,
  });

  @override
  Widget build(BuildContext context) {
    String displayName = selectedMember == "Self" 
        ? "$userName (Self)" 
        : (selectedMember as FamilyMember).fullName;

    return InkWell(
      onTap: () => _showMemberPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedMember == "Self" ? Icons.person_outline_rounded : Icons.group_outlined, 
                color: AppColors.primary, 
                size: 20
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(displayName, style: AppTextStyles.bodyLarge),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showMemberPicker(BuildContext context) {
    List<AtamanActionOption> options = [
      AtamanActionOption(
        title: "$userName (Self)",
        icon: Icons.person_outline_rounded,
        onTap: () => onMemberSelected("Self"),
      ),
      ...familyMembers.map((member) => AtamanActionOption(
        title: member.fullName,
        icon: Icons.group_outlined,
        onTap: () => onMemberSelected(member),
      )),
    ];

    AtamanActionSheet.show(
      context, 
      title: "Select Patient", 
      options: options
    );
  }
}
