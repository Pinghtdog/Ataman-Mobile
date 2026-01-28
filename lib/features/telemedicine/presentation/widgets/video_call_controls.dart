import 'package:flutter/material.dart';

class VideoCallControls extends StatelessWidget {
  final VoidCallback onHangup;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final bool isMuted;
  final bool isCameraOff;

  const VideoCallControls({
    super.key,
    required this.onHangup,
    this.onToggleMute,
    this.onToggleCamera,
    this.isMuted = false,
    this.isCameraOff = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onToggleMute != null) ...[
          FloatingActionButton(
            heroTag: 'mute',
            onPressed: onToggleMute,
            backgroundColor: isMuted ? Colors.white : Colors.white24,
            child: Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: isMuted ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(width: 20),
        ],
        FloatingActionButton(
          heroTag: 'hangup',
          onPressed: onHangup,
          backgroundColor: Colors.red,
          child: const Icon(Icons.call_end, color: Colors.white),
        ),
        if (onToggleCamera != null) ...[
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: onToggleCamera,
            backgroundColor: isCameraOff ? Colors.white : Colors.white24,
            child: Icon(
              isCameraOff ? Icons.videocam_off : Icons.videocam,
              color: isCameraOff ? Colors.black : Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
