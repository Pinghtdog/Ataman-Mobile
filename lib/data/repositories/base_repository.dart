import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/cache_manager.dart';

abstract class BaseRepository {
  final SupabaseClient supabase = Supabase.instance.client;
  final CacheManager cache = CacheManager();

  /// Helper to wrap network calls with error handling
  Future<T> safeCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      // Log error or handle specific Supabase errors
      throw Exception('Database Error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected Error: $e');
    }
  }

  /// Helper for cached queries
  Future<T> getCached<T>(String key, Future<T> Function() fetcher, {Duration? ttl}) async {
    final cachedData = cache.get<T>(key);
    if (cachedData != null) return cachedData;

    final freshData = await fetcher();
    cache.set(key, freshData, ttl: ttl);
    return freshData;
  }
}
