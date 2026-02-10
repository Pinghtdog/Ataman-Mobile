import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';
import '../../features/emergency/data/repositories/emergency_repository.dart';

class SyncService {
  final EmergencyRepository _emergencyRepository;
  final LocalStorageService _localStorage;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  SyncService(this._emergencyRepository, this._localStorage);

  Future<void> start() async {
    // Immediately attempt flush
    await _flushPending();

    // Listen for connectivity changes
    // connectivity_plus 6.x returns List<ConnectivityResult>
    _connSub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.any((result) => result != ConnectivityResult.none)) {
        if (kDebugMode) debugPrint('Connectivity restored - attempting to flush pending');
        await _flushPending();
      }
    });
  }

  Future<void> _flushPending() async {
    final pending = _localStorage.getPendingEmergencies();
    if (pending.isEmpty) return;

    if (kDebugMode) debugPrint('SyncService: Found ${pending.length} pending emergencies to sync');

    for (final item in pending) {
      final localId = item['id']?.toString() ?? '';
      try {
        // Attempt to create remotely
        // We use the map directly as the repository handles the conversion
        final created = await _emergencyRepository.createEmergencyRequestFromMap(item);
        
        // Map local -> remote for reference
        await _localStorage.mapLocalToRemote(localId, created.id);
        
        // Save to history box (now successfully synced)
        await _localStorage.saveEmergencyToHistory(created.toJson());
        
        // Remove from pending on success
        await _localStorage.removePendingEmergency(localId);
        
        if (kDebugMode) debugPrint('Successfully synced emergency $localId -> ${created.id}');
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to sync $localId: $e');
        
        // Try to resolve duplicates: look for matching existing remote request
        // This handles cases where the request reached the server but the app crashed/lost connection before recording the success
        try {
          final match = await _emergencyRepository.findMatchingRequest(
            userId: item['user_id']?.toString(),
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
          );
          
          if (match != null) {
            await _localStorage.mapLocalToRemote(localId, match.id);
            await _localStorage.saveEmergencyToHistory(match.toJson());
            await _localStorage.removePendingEmergency(localId);
            if (kDebugMode) debugPrint('Resolved conflict: Mapped pending $localId to existing remote ${match.id}');
          }
        } catch (e2) {
          if (kDebugMode) debugPrint('Duplicate resolution failed for $localId: $e2');
        }
      }
    }
  }

  Future<void> stop() async {
    await _connSub?.cancel();
  }
}
