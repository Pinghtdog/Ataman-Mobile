import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../widgets/video_call_controls.dart';

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
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _supabase = Supabase.instance.client;
  StreamSubscription? _callSubscription;
  StreamSubscription? _iceSubscription;

  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _setupCall();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _setupCall() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      _supabase.from('ice_candidates').insert({
        'call_id': widget.callId,
        'candidate': candidate.toMap(),
        'type': widget.isCaller ? 'caller' : 'receiver',
      }).then((_) {});
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    setState(() {
      _localRenderer.srcObject = _localStream;
    });

    if (widget.isCaller) {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      await _supabase.from('video_calls').update({
        'offer': offer.toMap()
      }).eq('id', widget.callId);
    }

    _listenForChanges();
  }

  void _listenForChanges() {
    _callSubscription = _supabase
        .from('video_calls')
        .stream(primaryKey: ['id'])
        .eq('id', widget.callId)
        .listen((data) async {
      if (data.isEmpty) return;
      final call = data.first;

      final remoteDesc = await _peerConnection!.getRemoteDescription();

      if (!widget.isCaller && call['offer'] != null && remoteDesc == null) {
        final offer = RTCSessionDescription(call['offer']['sdp'], call['offer']['type']);
        await _peerConnection!.setRemoteDescription(offer);
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        await _supabase.from('video_calls').update({
          'answer': answer.toMap(),
          'status': 'active'
        }).eq('id', widget.callId);
      }

      if (widget.isCaller && call['answer'] != null && remoteDesc == null) {
        final answer = RTCSessionDescription(call['answer']['sdp'], call['answer']['type']);
        await _peerConnection!.setRemoteDescription(answer);
        await _supabase.from('video_calls').update({
          'status': 'active'
        }).eq('id', widget.callId);
      }
    });

    _iceSubscription = _supabase
        .from('ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('call_id', widget.callId)
        .listen((data) {
      for (var candidateData in data) {
        final type = candidateData['type'];
        if ((widget.isCaller && type == 'receiver') || (!widget.isCaller && type == 'caller')) {
          final candidate = RTCIceCandidate(
            candidateData['candidate']['candidate'],
            candidateData['candidate']['sdpMid'],
            candidateData['candidate']['sdpMLineIndex'],
          );
          _peerConnection!.addCandidate(candidate);
        }
      }
    });
  }

  void _toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
      setState(() => _isMuted = !audioTrack.enabled);
    }
  }

  void _toggleCamera() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = !videoTrack.enabled;
      setState(() => _isCameraOff = !videoTrack.enabled);
    }
  }

  Future<void> _hangup() async {
    await _supabase.from('video_calls').update({
      'status': 'ended'
    }).eq('id', widget.callId);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    _callSubscription?.cancel();
    _iceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: RTCVideoView(_remoteRenderer)),
          Positioned(
            right: 20,
            top: 50,
            width: 120,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: VideoCallControls(
              onHangup: _hangup,
              onToggleMute: _toggleMute,
              onToggleCamera: _toggleCamera,
              isMuted: _isMuted,
              isCameraOff: _isCameraOff,
            ),
          )
        ],
      ),
    );
  }
}
