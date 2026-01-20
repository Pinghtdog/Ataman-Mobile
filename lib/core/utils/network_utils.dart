import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static bool _isOffline = false;

  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static void initialize(BuildContext context) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      
      if (isOffline != _isOffline) {
        _isOffline = isOffline;
        _showConnectivitySnackBar(context, isOffline);
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static void _showConnectivitySnackBar(BuildContext context, bool isOffline) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              isOffline ? "You are offline" : "Back online",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: isOffline ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isOffline ? 5 : 2),
      ),
    );
  }

  static Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
