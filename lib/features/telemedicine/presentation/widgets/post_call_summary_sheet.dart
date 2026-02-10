import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../injector.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../../booking/data/repositories/booking_repository.dart';

class PostCallSummarySheet extends StatefulWidget {
  final String callId;

  const PostCallSummarySheet({
    super.key,
    required this.callId,
  });

  @override
  State<PostCallSummarySheet> createState() => _PostCallSummarySheetState();
}

class _PostCallSummarySheetState extends State<PostCallSummarySheet> {
  final _notesController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isSummarizing = false;
  bool _isSchedulingFollowUp = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Consultation Ended",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Please provide brief notes from your call to generate an AI Medical Record.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "e.g., Discussed back pain, doctor advised rest and paracetamol...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: _isSummarizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(_isSummarizing ? "Summarizing..." : "Generate AI Medical Record"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3238),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSummarizing || _isSchedulingFollowUp ? null : _handleGenerateSummary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              icon: _isSchedulingFollowUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.calendar_today),
              label: Text(_isSchedulingFollowUp ? "Scheduling..." : "Auto-Schedule Follow-up"),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSummarizing || _isSchedulingFollowUp ? null : _handleAutoScheduleFollowUp,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleGenerateSummary() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    
    final patientProfile = authState.profile;
    if (patientProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Patient profile not found.")),
        );
      }
      return;
    }

    setState(() => _isSummarizing = true);
    try {
      // 1. Get the session details to find the doctor_id
      final sessionResponse = await _supabase
          .from('telemed_sessions')
          .select('doctor_id')
          .eq('id', widget.callId)
          .single();
      
      final doctorId = sessionResponse['doctor_id'];

      // 2. Generate AI SOAP Note
      final summary = await getIt<GeminiService>().summarizeConsultation(
        transcriptOrNotes: _notesController.text,
        patientProfile: {
          'full_name': patientProfile.fullName,
          'medical_id': patientProfile.id,
        },
      );

      // 3. Save to clinical_notes table
      await _supabase.from('clinical_notes').insert({
        'patient_id': patientProfile.id,
        'doctor_id': doctorId,
        'subjective_notes': summary['subjective'],
        'objective_notes': summary['objective'],
        'assessment': summary['assessment'],
        'plan': summary['plan'],
      });

      // 4. Update session status to completed
      await _supabase.from('telemed_sessions').update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.callId);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medical record generated and saved successfully.")),
        );
      }
    } catch (e) {
      debugPrint("Summary Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving record: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  Future<void> _handleAutoScheduleFollowUp() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    if (_notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide consultation notes first.")),
      );
      return;
    }

    setState(() => _isSchedulingFollowUp = true);
    try {
      // 1. Get AI Recommendation
      final recommendation = await getIt<GeminiService>().getFollowUpRecommendation(_notesController.text);
      
      final daysUntil = (recommendation['days_until_follow_up'] as int?) ?? 7;
      final reason = recommendation['reason'] ?? "Follow-up consultation";
      
      final appointmentTime = DateTime.now().add(Duration(days: daysUntil));
      // Set to a standard time like 9 AM
      final scheduledTime = DateTime(appointmentTime.year, appointmentTime.month, appointmentTime.day, 9, 0);

      // 2. Get session details to find doctor and facility
      final session = await _supabase
          .from('telemed_sessions')
          .select('doctor_id, telemed_doctors(facility_id, full_name)')
          .eq('id', widget.callId)
          .single();

      final facilityId = session['telemed_doctors']['facility_id'];
      
      // 3. Create Booking
      final booking = Booking(
        id: '', // Will be generated by DB
        userId: authState.user.id,
        facilityId: facilityId.toString(),
        facilityName: 'Same Facility', // Will be fetched by repo if needed
        appointmentTime: scheduledTime,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        natureOfVisit: 'Follow-up visit',
        chiefComplaint: reason,
      );

      await getIt<BookingRepository>().createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Follow-up scheduled for ${scheduledTime.day}/${scheduledTime.month} regarding: $reason"),
            backgroundColor: Colors.green,
          ),
        );
        // Also trigger the summary save
        await _handleGenerateSummary();
      }
    } catch (e) {
      debugPrint("Scheduling Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to schedule: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSchedulingFollowUp = false);
    }
  }
}
