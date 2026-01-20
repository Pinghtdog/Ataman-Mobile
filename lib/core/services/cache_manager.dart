import 'dart:async';

class CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  CacheEntry({required this.data, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, CacheEntry> _cache = {};

  // Default TTL: 5 minutes
  static const Duration defaultTTL = Duration(minutes: 5);

  void set(String key, dynamic value, {Duration? ttl}) {
    final expiryTime = DateTime.now().add(ttl ?? defaultTTL);
    _cache[key] = CacheEntry(data: value, expiryTime: expiryTime);
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    
    if (entry == null) return null;

    if (entry.isExpired) {
      invalidate(key);
      return null;
    }

    return entry.data as T?;
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}
