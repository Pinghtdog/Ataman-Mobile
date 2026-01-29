import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'dart:async';
import '../widgets/post_call_summary_sheet.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
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
  
  Widget? _localView;
  Widget? _remoteView;
  int? _remoteViewID;

  // These must match your ZegoCloud console keys
  final int appID = 1673152262;
  final String appSign = "a19851b6acec66db9bff65413ffc2c2c";

  @override
  void initState() {
    super.initState();
    _initZego();
    _waitForRoomID();
  }

  Future<void> _initZego() async {
    // Create ZegoExpressEngine
    await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
      appID,
      ZegoScenario.StandardVideoCall,
      appSign: appSign,
    ));

    // Listen for remote stream events
    ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, streamList, extendedData) {
      if (updateType == ZegoUpdateType.Add) {
        _startListeningToRemoteStream(streamList.first.streamID);
      }
    };
  }

  void _waitForRoomID() {
    // We check the video_calls table for the offer/room setup
    _callSubscription = _supabase
        .from('video_calls')
        .stream(primaryKey: ['id'])
        .eq('id', widget.callId)
        .listen((data) async {
      if (data.isNotEmpty) {
        final call = data.first;
        // In this implementation, the callId itself serves as the roomID
        if (_roomID == null) {
          setState(() {
            _roomID = widget.callId;
            _isLoading = false;
          });
          _joinRoom();
        }
      }
    });
  }

  Future<void> _joinRoom() async {
    if (_roomID == null) return;

    // Login to room
    await ZegoExpressEngine.instance.loginRoom(
      _roomID!,
      ZegoUser(widget.userId, "Patient_${widget.userId.substring(0, 4)}"),
    );

    // Create local view
    final view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas(viewID));
    });

    setState(() {
      _localView = view;
    });

    // Start publishing local stream
    ZegoExpressEngine.instance.startPublishingStream("stream_${widget.userId}");
  }

  Future<void> _startListeningToRemoteStream(String streamID) async {
    final view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      _remoteViewID = viewID;
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: ZegoCanvas(viewID));
    });

    setState(() {
      _remoteView = view;
    });
  }

  void _endCall() async {
    await ZegoExpressEngine.instance.logoutRoom(_roomID!);
    await ZegoExpressEngine.destroyEngine();
    _showPostCallSummary();
  }

  void _showPostCallSummary() {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => PostCallSummarySheet(callId: widget.callId),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (Full Screen)
          _remoteView ?? const Center(
            child: Text("Waiting for doctor...", style: TextStyle(color: Colors.white)),
          ),

          // Local Video (PIP)
          Positioned(
            top: 50,
            right: 20,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.grey[900],
                child: _localView ?? const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
