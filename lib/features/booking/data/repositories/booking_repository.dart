import '../../../../core/data/repositories/base_repository.dart';
import '../models/booking_model.dart';

class BookingRepository extends BaseRepository {
  
  Future<void> createBooking(Booking booking) async {
    await safeCall(() => supabase.from('bookings').insert(booking.toJson()));
    // Invalidate user's booking list cache
    cache.invalidate('user_bookings_${booking.userId}');
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    return await getCached<List<Booking>>(
      'user_bookings_$userId',
      () async {
        final response = await safeCall(() => supabase
            .from('bookings')
            .select()
            .eq('user_id', userId)
            .order('appointment_time', ascending: false));
        
        return (response as List).map((json) => Booking.fromJson(json)).toList();
      },
      ttl: const Duration(minutes: 2), // Short TTL for dynamic data
    );
  }

  Future<void> cancelBooking(String bookingId, String userId) async {
    await safeCall(() => supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId));
    
    cache.invalidate('user_bookings_$userId');
  }

  Stream<List<Booking>> watchUserBookings(String userId) {
    return supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('appointment_time', ascending: false)
        .map((data) => data.map((json) => Booking.fromJson(json)).toList());
  }
}
