import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/model/family_member_model.dart';
import '../../data/repositories/family_repository.dart';
import '../widgets/family_member_card.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../../injector.dart';
import '../../../vaccination/presentation/widgets/immunization_id_card.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  List<FamilyMember>? _members;
  bool _isLoading = true;
  
  final List<Color> _avatarColors = [
    Colors.pink.shade50,
    Colors.blue.shade50,
    Colors.orange.shade50,
    Colors.green.shade50,
    Colors.purple.shade50,
    Colors.cyan.shade50,
  ];

  final List<Color> _iconColors = [
    Colors.pink,
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.cyan,
  ];

  final List<String> _relationships = [
    'Mother',
    'Father',
    'Spouse',
    'Brother',
    'Sister',
    'Child',
    'Guardian',
  ];

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      try {
        final members = await getIt<FamilyRepository>().getFamilyMembers(authState.user!.id);
        if (mounted) {
          setState(() {
            _members = members;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showAddFamilyMemberDialog() {
    final nameController = TextEditingController();
    String? selectedRelationship;
    DateTime? selectedDate;
    String? selectedGender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Family Member", style: AppTextStyles.h2),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name", 
                  border: OutlineInputBorder(),
                  hintText: "Enter relative's full name",
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) => Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Relationship",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      hint: const Text("Select Relationship"),
                      items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setModalState(() => selectedRelationship = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(selectedDate == null ? "Birth Date" : DateFormat('MM/dd/yyyy').format(selectedDate!)),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setModalState(() => selectedDate = date);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Gender",
                              border: OutlineInputBorder(), 
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            hint: const Text("Gender"),
                            items: ["Male", "Female"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) => setModalState(() => selectedGender = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameController.text.isNotEmpty && selectedRelationship != null && selectedDate != null) {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is Authenticated) {
                      final medicalId = 'ATAM-F${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      
                      final newMember = FamilyMember(
                        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID for local UI
                        userId: authState.user!.id,
                        fullName: nameController.text,
                        relationship: selectedRelationship!,
                        birthDate: selectedDate,
                        gender: selectedGender,
                        medicalId: medicalId,
                        isVerified: true,
                      );

                      await getIt<FamilyRepository>().addFamilyMember(newMember);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadFamilyMembers();
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all required fields.')),
                    );
                  }
                },
                child: const Text("Save Family Member", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewIdDialog(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImmunizationIdCard(
              patientName: member.fullName,
              dob: member.birthDate != null ? DateFormat('MM/dd/yyyy').format(member.birthDate!) : 'N/A',
              immunizationId: member.medicalId ?? 'N/A',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        UserModel? primaryUser;
        if (authState is Authenticated) {
          primaryUser = authState.profile;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AtamanHeader(
                isSimple: true,
                height: 120,
                padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Family Members",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionHeader("PRIMARY PROFILE"),
                    if (primaryUser != null)
                      _buildPrimaryProfileCard(primaryUser)
                    else
                      const Center(child: CircularProgressIndicator()),
                    
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader("DEPENDENTS"),
                    
                    if (_isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_members == null || _members!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "No family members added yet.",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: List.generate(_members!.length, (index) {
                          final member = _members![index];
                          final age = member.birthDate != null 
                              ? (DateTime.now().difference(member.birthDate!).inDays / 365).floor()
                              : 0;
                          
                          final colorIndex = index % _avatarColors.length;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Dismissible(
                              key: Key(member.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
                              ),
                              confirmDismiss: (direction) async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Remove Member"),
                                    content: Text("Are you sure you want to remove ${member.fullName}?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true), 
                                        child: const Text("Remove", style: TextStyle(color: Colors.red))
                                      ),
                                    ],
                                  ),
                                );
                                return confirmed;
                              },
                              onDismissed: (direction) {
                                // 1. Immediately remove from local list to satisfy Dismissible requirement
                                final removedId = member.id;
                                setState(() {
                                  _members!.removeAt(index);
                                });
                                // 2. Perform background deletion
                                getIt<FamilyRepository>().deleteFamilyMember(removedId);
                              },
                              child: FamilyMemberCard(
                                name: member.fullName,
                                relationship: member.relationship,
                                age: age,
                                avatarColor: _avatarColors[colorIndex],
                                iconColor: _iconColors[colorIndex],
                                onViewId: () => _showViewIdDialog(member),
                              ),
                            ),
                          );
                        }),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    DottedBorder(
                      color: AppColors.primary,
                      strokeWidth: 2,
                      dashPattern: const [8, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(20),
                      child: InkWell(
                        onTap: _showAddFamilyMemberDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                "Add Family Member",
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPrimaryProfileCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Active Account",
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: AppColors.primary),
            onPressed: () {
              _showViewIdDialog(FamilyMember(
                id: user.id,
                userId: user.id,
                fullName: user.fullName,
                relationship: 'Self',
                birthDate: user.birthDate != null ? DateTime.tryParse(user.birthDate!) : null,
                medicalId: user.medicalId,
                isVerified: true,
              ));
            },
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
        ],
      ),
    );
  }
}
