import 'package:ataman/features/triage/presentation/screens/triage_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injector.dart';
import '../../data/models/triage_model.dart';
import '../../domain/repositories/i_triage_repository.dart';

/// [TriageHistoryScreen] displays a historical record of the user's past medical assessments.
///
/// This screen provides a centralized view for users to revisit their triage results,
/// helping them track recurring symptoms or review clinical notes (SOAP notes)
/// generated during previous sessions.
///
/// **Key Features:**
/// 1. **Chronological History**: Fetches and lists past triage results using the [ITriageRepository].
/// 2. **Urgency Categorization**: Uses visual badges to highlight the severity of 
///    past assessments (e.g., Emergency, Urgent, Routine).
/// 3. **Deep Dive**: Allows users to tap on a history card to view the full 
///    [TriageResultScreen] for a specific past session.
/// 4. **SOAP Note Accessibility**: Provides a clear call-to-action to review 
///    Subjective, Objective, Assessment, and Plan notes for each entry.
class TriageHistoryScreen extends StatefulWidget {
  const TriageHistoryScreen({super.key});

  @override
  State<TriageHistoryScreen> createState() => _TriageHistoryScreenState();
}

/// The state for [TriageHistoryScreen]. 
/// Manages fetching and displaying the list of past triage assessments.
class _TriageHistoryScreenState extends State<TriageHistoryScreen> {
  /// A Future that completes with the list of the user's triage history.
  late Future<List<TriageResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the user's triage history from the repository on initialization.
    _historyFuture = getIt<ITriageRepository>().getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanHeader(
            isSimple: true,
            height: 130,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Medical Assessments",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                // const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TriageResult>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                
                if (snapshot.hasError) {
                  return AtamanErrorState(
                    title: "Load Error",
                    message: "Unable to retrieve your medical history. Please try again later.",
                    onAction: () => setState(() {
                      _historyFuture = getIt<ITriageRepository>().getHistory();
                    }),
                  );
                }

                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return const AtamanEmptyState(
                    title: "No Assessments Yet",
                    message: "Perform your first Smart Triage to see your medical records here.",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.p20),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _buildHistoryCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a card representing a single triage assessment.
  /// Displays the date, urgency level, summary, and specialty.
  Widget _buildHistoryCard(TriageResult item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.urgencyColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showResultDetails(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(item.createdAt ?? DateTime.now()),
                      style: AppTextStyles.caption,
                    ),
                    AtamanBadge(
                      text: item.urgency.name.toUpperCase(),
                      color: item.urgencyColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.summaryForProvider ?? "Medical Assessment",
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(item.specialty, style: AppTextStyles.bodySmall),
                    const Spacer(),
                    Text(
                      "View SOAP Notes",
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navigates to the [TriageResultScreen] to display the full details of a past assessment.
  void _showResultDetails(TriageResult item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TriageResultScreen(result: item)),
    );
  }
}
