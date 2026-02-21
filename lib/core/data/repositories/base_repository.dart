import 'package:supabase_flutter/supabase_flutter.dart';
import '../../error/failures.dart';
import '../../services/cache_manager.dart';

/// An abstract base class for repositories that provides common utilities for
/// data handling, including error management and caching.
///
/// **Features:**
/// 1. **Supabase Client**: Provides a direct instance of [SupabaseClient] for database interactions.
/// 2. **Cache Manager**: Includes a [CacheManager] for in-memory caching.
/// 3. **Safe API Calls**: A [safeCall] method to wrap repository calls in a standardized 
///    try-catch block, converting Supabase exceptions into custom [Failure] types.
/// 4. **Cache-Aside Pattern**: A [getCached] method to abstract the logic of checking 
///    the cache before fetching from the network.
abstract class BaseRepository {
  /// An instance of the Supabase client for database and authentication operations.
  final SupabaseClient supabase = Supabase.instance.client;
  
  /// An instance of the local cache manager for storing and retrieving temporary data.
  final CacheManager cache = CacheManager();

  /// A generic wrapper for executing database or network calls that safely handles exceptions.
  ///
  /// It catches specific exceptions like [PostgrestException] and [AuthException]
  /// and re-throws them as domain-specific [Failure] types (e.g., [ServerFailure],
  /// [AuthenticationFailure]). This centralizes error handling and ensures consistency
  /// across all repositories.
  ///
  /// Returns the result of the `call` function if successful.
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

  /// Implements a cache-aside pattern for data retrieval.
  ///
  /// It first checks the cache for data associated with the given [key].
  /// - If data is found (a "cache hit"), it returns the cached data immediately.
  /// - If data is not found (a "cache miss"), it executes the [fetcher] function to 
  ///   get fresh data, stores it in the cache with an optional [ttl] (Time To Live),
  ///   and then returns the fresh data.
  ///
  /// This helps reduce redundant network requests and improves app performance.
  Future<T> getCached<T>(String key, Future<T> Function() fetcher, {Duration? ttl}) async {
    final cachedData = cache.get<T>(key);
    if (cachedData != null) return cachedData;

    final freshData = await fetcher();
    cache.set(key, freshData, ttl: ttl);
    return freshData;
  }
}
