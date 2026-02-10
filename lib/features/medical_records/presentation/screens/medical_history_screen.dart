import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/medical_document_service.dart';
import '../../../../injector.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/models/medical_history_model.dart';
import '../../logic/medical_history_cubit.dart';
import '../widgets/medical_history_timeline_item.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Consultations", "Labs", "Referrals"];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<MedicalHistoryCubit>().fetchHistory(authState.user.id);
    }
  }

  Future<void> _handleUpload() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    setState(() => _isUploading = true);

    try {
      final String? url = await getIt<MedicalDocumentService>().pickAndUploadDocument(
        userId: authState.user.id,
        folder: 'uploads',
      );

      if (url != null && mounted) {
        // Create a new history item for the upload
        final newItem = MedicalHistoryItem(
          id: '', // Will be generated
          title: 'Document Upload',
          subtitle: 'User Uploaded File',
          date: DateTime.now(),
          type: MedicalRecordType.lab,
          fileUrl: url,
          hasPdf: url.toLowerCase().contains('.pdf'),
          tag: 'Uploaded',
        );

        await context.read<MedicalHistoryCubit>().addHistoryItem(newItem, authState.user.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document uploaded successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _handleUpload,
        backgroundColor: AppColors.primary,
        icon: _isUploading 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.upload_file, color: Colors.white),
        label: Text(_isUploading ? "Uploading..." : "Upload Document", style: const TextStyle(color: Colors.white)),
      ),
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
                  "Medical History",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (filter == "Referrals") {
                        Navigator.of(context).pushNamed(AppRoutes.referrals);
                      } else {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF333333) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: BlocBuilder<MedicalHistoryCubit, MedicalHistoryState>(
              builder: (context, state) {
                if (state is MedicalHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MedicalHistoryError) {
                  return Center(child: Text("Error: ${state.message}"));
                }

                if (state is MedicalHistoryLoaded) {
                  final filteredItems = state.history.where((item) {
                    if (_selectedFilter == "All") return true;
                    if (_selectedFilter == "Consultations") return item.type == MedicalRecordType.consultation;
                    if (_selectedFilter == "Labs") return item.type == MedicalRecordType.lab;
                    return true;
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return AtamanEmptyState(
                      title: "No Records Found",
                      message: "Complete a triage session or upload a document to see your history here.",
                      onRetry: _loadHistory,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 80),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return MedicalHistoryTimelineItem(
                        item: filteredItems[index],
                        isLast: index == filteredItems.length - 1,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
