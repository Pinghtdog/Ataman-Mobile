import 'package:intl/intl.dart';
import '../../../../core/data/repositories/base_repository.dart';
import '../models/booking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository extends BaseRepository {
  
  Future<void> createBooking(Booking booking) async {
    // 1. Double check slot availability at the database level
    final isAvailable = await isSlotAvailable(
      booking.facilityId,
      booking.appointmentTime,
      booking.serviceId ?? ''
    );

    if (!isAvailable) {
      throw Exception("This time slot is already fully booked. Please select another time.");
    }

    await safeCall(() => supabase.from('bookings').insert(booking.toJson()));

    // 2. Insert into notifications table for the user
    await safeCall(() => supabase.from('notifications').insert({
      'user_id': booking.userId,
      'title': 'Booking Confirmed!',
      'body': 'Your appointment at ${booking.facilityName} is scheduled for ${DateFormat('MMM dd, h:mm a').format(booking.appointmentTime)}.',
      'type': 'booking',
      'data': {'booking_id': booking.id},
    }));

    // Invalidate user's booking list cache
    cache.invalidate('user_bookings_${booking.userId}');
  }

  Future<bool> isSlotAvailable(String facilityId, DateTime time, String serviceId) async {
    // Check how many bookings exist for this specific time slot and service
    final response = await supabase
        .from('bookings')
        .select('*')
        .eq('facility_id', facilityId)
        .eq('appointment_time', time.toIso8601String())
        .eq('status', 'confirmed');

    final int count = (response as List).length;

    // Fetch facility service to get max_slots
    final serviceResponse = await supabase
        .from('facility_services')
        .select('max_slots_per_time_slot')
        .eq('id', serviceId)
        .single();

    final int maxSlots = serviceResponse['max_slots_per_time_slot'] ?? 2;

    return count < maxSlots;
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
      ttl: const Duration(minutes: 2),
    );
  }

  Future<void> cancelBooking(String bookingId, String userId) async {
    await safeCall(() => supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId));
    
    cache.invalidate('user_bookings_$userId');
  }

  Future<List<String>> getOccupiedSlots(String facilityId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all confirmed bookings for the day
    final response = await supabase
        .from('bookings')
        .select('appointment_time, service_id')
        .eq('facility_id', facilityId)
        .eq('status', 'confirmed')
        .gte('appointment_time', startOfDay.toIso8601String())
        .lt('appointment_time', endOfDay.toIso8601String());

    final List<dynamic> bookings = response as List;

    // Group by time and count
    Map<String, int> timeCounts = {};
    for (var b in bookings) {
      String time = b['appointment_time'];
      timeCounts[time] = (timeCounts[time] ?? 0) + 1;
    }

    // Mark as occupied if count >= max_slots (we assume a default of 2 here for simplicity)
    List<String> occupied = [];
    timeCounts.forEach((time, count) {
      if (count >= 2) {
        occupied.add(DateFormat('hh:mm a').format(DateTime.parse(time)));
      }
    });

    return occupied;
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
