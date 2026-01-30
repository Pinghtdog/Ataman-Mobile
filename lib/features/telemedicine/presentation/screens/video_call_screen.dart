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
    await _initZego();
    if (_isEngineCreated) {
      setState(() {
        _roomID = widget.callId;
        _isLoading = false;
      });
      
      _joinRoom();
      _listenToSessionMetadata();
    }
  }

  Future<void> _initZego() async {
    if (appID == 0 || appSign.isEmpty) {
      debugPrint("Zego Credentials missing in .env");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video call service not configured")),
        );
        Navigator.pop(context);
      }
      return;
    }

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
      await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
        appID,
        ZegoScenario.Default,
        appSign: kIsWeb ? null : appSign, 
      ));
      
      setState(() => _isEngineCreated = true);
      debugPrint("Zego Engine Created Successfully");

      ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, streamList, extendedData) {
        if (updateType == ZegoUpdateType.Add) {
          _startListeningToRemoteStream(streamList.first.streamID);
        }
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
      (data) async {
        if (data.isNotEmpty) {
          setState(() {
            _sessionData = data.first;
          });
        }
      },
      onError: (error) {
        debugPrint("Supabase Metadata Stream Error: $error");
      },
    );
  }

  Future<void> _joinRoom() async {
    if (_roomID == null || !_isEngineCreated) return;

    String displayName = "User_${widget.userId.length > 4 ? widget.userId.substring(0, 4) : widget.userId}";

    ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();

    debugPrint("Joining Room: $_roomID");
    
    await ZegoExpressEngine.instance.loginRoom(
      _roomID!,
      ZegoUser(widget.userId, displayName),
      config: config,
    );

    final view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas(viewID));
    });

    setState(() => _localView = view);
    ZegoExpressEngine.instance.startPublishingStream("stream_${widget.userId}");
  }

  Future<void> _startListeningToRemoteStream(String streamID) async {
    if (!_isEngineCreated) return;
    
    final view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      _remoteViewID = viewID;
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: ZegoCanvas(viewID));
    });

    setState(() => _remoteView = view);
  }

  void _endCall() async {
    if (_roomID != null && _isEngineCreated) {
      await ZegoExpressEngine.instance.logoutRoom(_roomID!);
      await ZegoExpressEngine.destroyEngine();
      setState(() => _isEngineCreated = false);
    }
    _showPostCallSummary();
  }

  void _showPostCallSummary() {
    if (!mounted) return;
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
          _remoteView ?? const Center(
            child: Text("Waiting for other participant...", style: TextStyle(color: Colors.white70)),
          ),
          
          // Debug/Session Info Overlay
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
                  const Text(
                    "Session Debug Info",
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Room ID: $_roomID",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (_roomID != null) {
                            Clipboard.setData(ClipboardData(text: _roomID!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Room ID copied"), duration: Duration(seconds: 1)),
                            );
                          }
                        },
                        child: const Icon(Icons.copy, color: Colors.blue, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Session Key: ${widget.callId.substring(0, 8)}...",
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  if (_sessionData != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "DB Status: ${_sessionData!['status'] ?? 'unknown'}",
                      style: TextStyle(
                        color: _sessionData!['status'] == 'ongoing' ? Colors.green : Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
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
                color: Colors.grey[900],
                child: _localView ?? const Center(child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2)),
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
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
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
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Initialising Video...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
