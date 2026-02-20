import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  static const String _pendingBox = 'pending_emergencies';
  static const String _idMapBox = 'id_map';
  static const String _hiveKeyStorage = 'hive_encryption_key';
  static const String _historyBox = 'emergency_history';
  
  // Boxes for Offline functionality
  static const String _facilityCacheBox = 'facility_cache';
  static const String _prescriptionCacheBox = 'prescription_cache';
  static const String _profileCacheBox = 'profile_cache';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  late final List<int> _encryptionKey;

  Future<void> init() async {
    await Hive.initFlutter();

    String? storedKey = await _secureStorage.read(key: _hiveKeyStorage);
    if (storedKey == null) {
      _encryptionKey = Hive.generateSecureKey();
      await _secureStorage.write(key: _hiveKeyStorage, value: base64Encode(_encryptionKey));
    } else {
      _encryptionKey = base64Decode(storedKey);
    }

    final cipher = HiveAesCipher(_encryptionKey);
    await Hive.openBox<String>(_pendingBox, encryptionCipher: cipher);
    await Hive.openBox<String>(_idMapBox, encryptionCipher: cipher);
    await Hive.openBox<String>(_historyBox, encryptionCipher: cipher);
    await Hive.openBox<String>(_facilityCacheBox, encryptionCipher: cipher);
    await Hive.openBox<String>(_prescriptionCacheBox, encryptionCipher: cipher);
    await Hive.openBox<String>(_profileCacheBox, encryptionCipher: cipher);
  }

  // --- FACILITY OFFLINE CACHE ---
  Future<void> cacheFacilities(List<Map<String, dynamic>> facilities) async {
    final box = Hive.box<String>(_facilityCacheBox);
    await box.clear();
    for (var f in facilities) {
      await box.put(f['id'].toString(), jsonEncode(f));
    }
  }

  List<Map<String, dynamic>> getCachedFacilities() {
    final box = Hive.box<String>(_facilityCacheBox);
    return box.values.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  // --- PRESCRIPTION OFFLINE CACHE ---
  Future<void> cachePrescriptions(List<Map<String, dynamic>> prescriptions) async {
    final box = Hive.box<String>(_prescriptionCacheBox);
    await box.clear();
    for (var p in prescriptions) {
      await box.put(p['id'].toString(), jsonEncode(p));
    }
  }

  List<Map<String, dynamic>> getCachedPrescriptions() {
    final box = Hive.box<String>(_prescriptionCacheBox);
    return box.values.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  // --- PROFILE OFFLINE CACHE ---
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    final box = Hive.box<String>(_profileCacheBox);
    await box.put('current_user', jsonEncode(profile));
  }

  Map<String, dynamic>? getCachedUserProfile() {
    final box = Hive.box<String>(_profileCacheBox);
    final data = box.get('current_user');
    return data != null ? jsonDecode(data) : null;
  }

  // --- EMERGENCY LOGIC ---
  Future<String> savePendingEmergency(Map<String, dynamic> data) async {
    final box = Hive.box<String>(_pendingBox);
    final id = (data['id'] != null && data['id'].isNotEmpty ? data['id'] : 'local-${DateTime.now().millisecondsSinceEpoch}').toString();
    final payload = jsonEncode({...data, 'id': id});
    await box.put(id, payload);
    return id;
  }

  List<Map<String, dynamic>> getPendingEmergencies() {
    final box = Hive.box<String>(_pendingBox);
    return box.values.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<void> removePendingEmergency(String id) async {
    await Hive.box<String>(_pendingBox).delete(id);
  }

  Future<void> mapLocalToRemote(String localId, String remoteId) async {
    final box = Hive.box<String>(_idMapBox);
    await box.put(localId, remoteId);
  }

  String? getRemoteId(String localId) {
    final box = Hive.box<String>(_idMapBox);
    return box.get(localId);
  }
  
  Future<void> saveEmergencyToHistory(Map<String, dynamic> json) async {
    final box = Hive.box<String>(_historyBox);
    final id = json['id']?.toString();
    if (id != null) {
      await box.put(id, jsonEncode(json));
    }
  }

  List<Map<String, dynamic>> getEmergencyHistory() {
    final box = Hive.box<String>(_historyBox);
    return box.values.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<void> clearAllData() async {
    await Hive.box<String>(_pendingBox).clear();
    await Hive.box<String>(_idMapBox).clear();
    await Hive.box<String>(_historyBox).clear();
    await Hive.box<String>(_facilityCacheBox).clear();
    await Hive.box<String>(_prescriptionCacheBox).clear();
    await Hive.box<String>(_profileCacheBox).clear();
  }
}
