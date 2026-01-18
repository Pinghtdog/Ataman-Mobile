import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createBooking(Booking booking) async {
    try {
      await _supabase.from('bookings').insert(booking.toJson());
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('appointment_time', ascending: false);
      
      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Stream<List<Booking>> watchUserBookings(String userId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('appointment_time', ascending: false)
        .map((data) => data.map((json) => Booking.fromJson(json)).toList());
  }
}
