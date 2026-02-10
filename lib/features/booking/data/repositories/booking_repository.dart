import 'package:intl/intl.dart';
import '../../../../core/data/repositories/base_repository.dart';
import '../models/booking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository extends BaseRepository {
  
  Future<void> createBooking(Booking booking) async {
    // 1. Check if the USER already has a booking at this exact time
    final hasExisting = await _userHasBookingAtTime(booking.userId, booking.appointmentTime);
    if (hasExisting) {
      throw Exception("You already have an active appointment scheduled for this time.");
    }

    // 2. Double check FACILITY slot availability
    final isAvailable = await isSlotAvailable(
      booking.facilityId,
      booking.appointmentTime,
      booking.serviceId ?? ''
    );

    if (!isAvailable) {
      throw Exception("This time slot is already fully booked. Please select another time.");
    }

    await safeCall(() => supabase.from('bookings').insert(booking.toJson()));

    // 3. Insert into notifications table
    await safeCall(() => supabase.from('notifications').insert({
      'user_id': booking.userId,
      'title': 'Booking Confirmed!',
      'body': 'Your appointment at ${booking.facilityName} is scheduled for ${DateFormat('MMM dd, h:mm a').format(booking.appointmentTime)}.',
      'type': 'booking',
      'data': {'booking_id': booking.id},
    }));

    cache.invalidate('user_bookings_${booking.userId}');
  }

  Future<bool> _userHasBookingAtTime(String userId, DateTime time) async {
    final response = await supabase
        .from('bookings')
        .select('id')
        .eq('user_id', userId)
        .eq('appointment_time', time.toIso8601String())
        .inFilter('status', ['pending', 'confirmed']);
    
    return (response as List).isNotEmpty;
  }

  Future<bool> isSlotAvailable(String facilityId, DateTime time, String serviceId) async {
    final response = await supabase
        .from('bookings')
        .select('*')
        .eq('facility_id', facilityId)
        .eq('appointment_time', time.toIso8601String())
        .eq('status', 'confirmed');

    final int count = (response as List).length;

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

    final response = await supabase
        .from('bookings')
        .select('appointment_time, service_id')
        .eq('facility_id', facilityId)
        .eq('status', 'confirmed')
        .gte('appointment_time', startOfDay.toIso8601String())
        .lt('appointment_time', endOfDay.toIso8601String());

    final List<dynamic> bookingsData = response as List;

    final servicesResponse = await supabase
        .from('facility_services')
        .select('id, max_slots_per_time_slot')
        .eq('facility_id', facilityId);

    final Map<String, int> serviceCapacities = {
      for (var s in (servicesResponse as List)) s['id'].toString(): s['max_slots_per_time_slot'] ?? 2
    };

    Map<String, int> timeServiceCounts = {};
    for (var b in bookingsData) {
      String key = "${b['appointment_time']}_${b['service_id']}";
      timeServiceCounts[key] = (timeServiceCounts[key] ?? 0) + 1;
    }

    Set<String> occupiedTimes = {};
    timeServiceCounts.forEach((key, count) {
      final parts = key.split('_');
      final timeStr = parts[0];
      final sId = parts[1];

      final capacity = serviceCapacities[sId] ?? 2;
      if (count >= capacity) {
        occupiedTimes.add(DateFormat('hh:mm a').format(DateTime.parse(timeStr)));
      }
    });

    return occupiedTimes.toList();
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
