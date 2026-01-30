import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/post_call_summary_sheet.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId; // This corresponds to telemed_sessions.id
  final String userId;
  final bool isCaller;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.userId,
    required this.isCaller,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _supabase = Supabase.instance.client;
  StreamSubscription? _callSubscription;
  String? _roomID;
  bool _isLoading = true;
  bool _isEngineCreated = false;
  Map<String, dynamic>? _sessionData;
  
  Widget? _localView;
  Widget? _remoteView;
  int? _remoteViewID;

  // CREDENTIALS (Dynamic from .env)
  final int appID = int.parse(dotenv.env['ZEGO_APP_ID'] ?? '0');
  final String appSign = dotenv.env['ZEGO_APP_SIGN'] ?? '';

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    // 1. Fetch the latest session data to get the meeting_link if it exists
    final response = await _supabase
        .from('telemed_sessions')
        .select('meeting_link')
        .eq('id', widget.callId)
        .single();
    
    final existingLink = response['meeting_link'];

    await _initZego();
    if (_isEngineCreated) {
      setState(() {
        // SYNC FIX: If Web already generated a secure ATAMAN-XXXX link, use it.
        // Otherwise, fallback to callId until it's updated.
        _roomID = (existingLink != null && existingLink.toString().startsWith('ATAMAN-')) 
            ? existingLink.toString() 
            : widget.callId;
        _isLoading = false;
      });
      
      await _joinRoom();
      _listenToSessionMetadata();
    }
  }

  Future<void> _initZego() async {
    if (appID == 0 || appSign.isEmpty) {
      debugPrint("Zego Credentials missing in .env");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video call service not configured. Check .env")),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera and Microphone permissions are required")),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      // Initialize Zego Engine
      await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
        appID,
        ZegoScenario.Default,
        appSign: kIsWeb ? null : appSign, 
      ));
      
      setState(() => _isEngineCreated = true);
      debugPrint("Zego Engine Created Successfully");

      // Handle remote stream events
      ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, streamList, extendedData) {
        if (updateType == ZegoUpdateType.Add) {
          _startListeningToRemoteStream(streamList.first.streamID);
        } else if (updateType == ZegoUpdateType.Delete) {
          setState(() => _remoteView = null);
        }
      };

      // Handle room state changes
      ZegoExpressEngine.onRoomStateUpdate = (roomID, state, errorCode, extendedData) {
        debugPrint("Room State: $state, ErrorCode: $errorCode");
      };

    } catch (e) {
      debugPrint("Failed to create Zego Engine: $e");
    }
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
          
          // SYNC FIX: If the meeting_link changes (e.g. Web generates an ATAMAN-ID), 
          // we should switch rooms if we haven't already.
          final newLink = session['meeting_link'];
          if (newLink != null && newLink != _roomID && newLink.toString().startsWith('ATAMAN-')) {
             _switchRoom(newLink.toString());
          }

          if (session['status'] == 'completed') {
            _endCall(updateDb: false);
          }
        }
      },
      onError: (error) {
        debugPrint("Supabase Metadata Stream Error: $error");
      },
    );
  }

  Future<void> _switchRoom(String newRoomID) async {
    if (!_isEngineCreated) return;
    await ZegoExpressEngine.instance.logoutRoom(_roomID!);
    setState(() {
      _roomID = newRoomID;
    });
    await _joinRoom();
  }

  Future<void> _joinRoom() async {
    if (_roomID == null || !_isEngineCreated) return;

    String displayName = widget.isCaller ? "Patient" : "Doctor";
    ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
    
    debugPrint("Joining Room: $_roomID as $displayName");
    
    await ZegoExpressEngine.instance.loginRoom(
      _roomID!,
      ZegoUser(widget.userId, displayName),
      config: config,
    );

    await _updateSessionToActive();

    final view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas(viewID));
    });

    setState(() => _localView = view);
    ZegoExpressEngine.instance.startPublishingStream("stream_${widget.userId}");
  }

  Future<void> _updateSessionToActive() async {
    try {
      final updates = {
        'status': 'active',
        // If we are using the secure ATAMAN-ID, preserve it.
        'meeting_link': _roomID,
      };
      
      if (_sessionData?['started_at'] == null) {
        updates['started_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('telemed_sessions')
          .update(updates)
          .eq('id', widget.callId);
          
    } catch (e) {
      debugPrint("Error updating session to active: $e");
    }
  }

  Future<void> _startListeningToRemoteStream(String streamID) async {
    if (!_isEngineCreated) return;
    
    final view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      _remoteViewID = viewID;
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: ZegoCanvas(viewID));
    });

    setState(() => _remoteView = view);
  }

  void _endCall({bool updateDb = true}) async {
    if (updateDb) {
      try {
        await _supabase
            .from('telemed_sessions')
            .update({
              'status': 'completed',
              'ended_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.callId);
      } catch (e) {
        debugPrint("Error updating session to completed: $e");
      }
    }

    if (_roomID != null && _isEngineCreated) {
      await ZegoExpressEngine.instance.logoutRoom(_roomID!);
      await ZegoExpressEngine.destroyEngine();
      setState(() => _isEngineCreated = false);
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
    if (_isEngineCreated) {
      ZegoExpressEngine.destroyEngine();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _remoteView ?? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  widget.isCaller ? "Waiting for Doctor..." : "Waiting for Patient...",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          
          Positioned(
            top: 50,
            right: 20,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: _localView ?? const Center(
                  child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isCaller ? "PATIENT MODE" : "DOCTOR MODE",
                    style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Room: ${_roomID?.substring(0, 8)}...",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_sessionData != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Status: ${_sessionData!['status']?.toUpperCase() ?? 'PENDING'}",
                      style: TextStyle(
                        color: _sessionData!['status'] == 'active' ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: "mic",
                  onPressed: () {},
                  backgroundColor: Colors.white10,
                  child: const Icon(Icons.mic, color: Colors.white),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: "end_call",
                  onPressed: () => _endCall(),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: "camera",
                  onPressed: () {},
                  backgroundColor: Colors.white10,
                  child: const Icon(Icons.videocam, color: Colors.white),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text("Connecting to Ataman Telemedicine...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
