import 'package:supabase_flutter/supabase_flutter.dart';
import '../../error/failures.dart';
import '../../services/cache_manager.dart';

abstract class BaseRepository {
  final SupabaseClient supabase = Supabase.instance.client;
  final CacheManager cache = CacheManager();

  Future<T> safeCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    } on AuthException catch (e) {
      throw AuthenticationFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<T> getCached<T>(String key, Future<T> Function() fetcher, {Duration? ttl}) async {
    final cachedData = cache.get<T>(key);
    if (cachedData != null) return cachedData;

    final freshData = await fetcher();
    cache.set(key, freshData, ttl: ttl);
    return freshData;
  }
}
