import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/post_call_summary_sheet.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId; // This corresponds to telemed_sessions.id
  final String userId;
  final String userName;
  final bool isCaller;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.userId,
    required this.userName,
    required this.isCaller,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _supabase = Supabase.instance.client;
  StreamSubscription? _callSubscription;
  Map<String, dynamic>? _sessionData;

  // CREDENTIALS (Dynamic from .env)
  final int appID = int.parse(dotenv.env['ZEGO_APP_ID'] ?? '0');
  final String appSign = dotenv.env['ZEGO_APP_SIGN'] ?? '';

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // Verify credentials
    if (appID == 0 || appSign.isEmpty) {
      debugPrint("Zego Credentials missing in .env");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Video call service not configured. Check .env")),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Listen to session metadata for call completion
    _listenToSessionMetadata();

    // Update session to active
    await _updateSessionToActive();
  }

  void _listenToSessionMetadata() {
    _callSubscription = _supabase
        .from('telemed_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', widget.callId)
        .listen(
          (data) {
            if (data.isNotEmpty) {
              final session = data.first;
              setState(() {
                _sessionData = session;
              });

              // End call if session is completed
              if (session['status'] == 'completed' && mounted) {
                _endCall(updateDb: false);
              }
            }
          },
          onError: (error) {
            debugPrint("Supabase Metadata Stream Error: $error");
          },
        );
  }

  Future<void> _updateSessionToActive() async {
    try {
      await _supabase
          .from('telemed_sessions')
          .update({
            'status': 'active',
            'meeting_link': widget.callId,
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.callId)
          .select()
          .single();
    } catch (e) {
      debugPrint("Error updating session to active: $e");
    }
  }

  void _endCall({bool updateDb = true}) async {
    if (updateDb) {
      try {
        await _supabase.from('telemed_sessions').update({
          'status': 'completed',
          'ended_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.callId);
      } catch (e) {
        debugPrint("Error updating session to completed: $e");
      }
    }

    if (mounted) {
      _showPostCallSummary();
    }
  }

  void _showPostCallSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PostCallSummarySheet(callId: widget.callId),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: appID,
      appSign: appSign,
      userID: widget.userId,
      userName: widget.userName,
      callID: widget.callId,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..onOnlySelfInRoom = (context) => _endCall()
          ..onCallEnd = (List<String> callIDList, String userID) async {
            await _endCall();
          }
          ..bottomMenuBarConfig = ZegoBottomMenuBarConfig(
            maxShowCount: 5,
            extendButtons: [
              ElevatedButton(
                onPressed: () => _endCall(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('End Call',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          )
          ..topMenuBarConfig = ZegoTopMenuBarConfig(
            title:
                '${widget.isCaller ? "Patient" : "Doctor"} - Ataman Telemedicine',
            isVisible: true,
          ),
    );
  }
}
