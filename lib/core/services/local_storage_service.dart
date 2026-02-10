import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  static const String _pendingBox = 'pending_emergencies';
  static const String _idMapBox = 'id_map';
  static const String _hiveKeyStorage = 'hive_encryption_key';
  static const String _historyBox = 'emergency_history';

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
  }

  Future<String> savePendingEmergency(Map<String, dynamic> data) async {
    final box = Hive.box<String>(_pendingBox);
    final id = (data['id'] != null && data['id'].isNotEmpty ? data['id'] : 'local-${DateTime.now().millisecondsSinceEpoch}').toString();
    final payload = jsonEncode({...data, 'id': id});
    await box.put(id, payload);
    if (kDebugMode) debugPrint('Saved pending emergency: $id');
    return id;
  }

  List<Map<String, dynamic>> getPendingEmergencies() {
    final box = Hive.box<String>(_pendingBox);
    if (box.isEmpty) return [];
    try {
      return box.values.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    } catch(e) {
      if (kDebugMode) debugPrint('Error decoding pending emergencies: $e. Clearing corrupted data.');
      box.clear();
      return [];
    }
  }

  Future<void> removePendingEmergency(String id) async {
    final box = Hive.box<String>(_pendingBox);
    await box.delete(id);
    if (kDebugMode) debugPrint('Removed pending emergency: $id');
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
    if (box.isEmpty) return [];
    try {
      return box.values.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    } catch(e) {
      if (kDebugMode) debugPrint('Error decoding emergency history: $e. Clearing corrupted data.');
      box.clear();
      return [];
    }
  }
  
  Future<void> clearAllData() async {
    await Hive.box<String>(_pendingBox).clear();
    await Hive.box<String>(_idMapBox).clear();
    await Hive.box<String>(_historyBox).clear();
  }
}
