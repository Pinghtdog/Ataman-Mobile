import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/notification_service.dart';
import '../../../injector.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import '../../medical_records/data/repositories/referral_repository.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _bookingRepository;
  final ReferralRepository _referralRepository;
  StreamSubscription? _bookingsSubscription;

  BookingCubit({
    required BookingRepository bookingRepository,
    required ReferralRepository referralRepository,
  })  : _bookingRepository = bookingRepository,
        _referralRepository = referralRepository,
        super(BookingInitial());

  Future<void> createBooking(Booking booking, {bool isEmergencyReferral = false}) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.createBooking(booking);
      
      // 1. Trigger Push Notification locally
      await getIt<NotificationService>().showNotification(
        title: 'Booking Confirmed!',
        body: 'Your appointment at ${booking.facilityName} is successfully scheduled.',
      );

      // 2. Automatic Rapid Referral logic for Booking
      if (isEmergencyReferral) {
        await _referralRepository.createRapidReferralFromBooking(
          userId: booking.userId,
          booking: booking,
        );
      }
      
      emit(BookingLoaded([booking]));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  void startWatchingBookings(String userId) {
    emit(BookingLoading());
    _bookingsSubscription?.cancel();
    _bookingsSubscription = _bookingRepository.watchUserBookings(userId).listen(
      (bookings) {
        emit(BookingLoaded(bookings));
      },
      onError: (error) {
        emit(BookingError(error.toString()));
      },
    );
  }

  Future<void> cancelBooking(String bookingId, String userId) async {
    try {
      await _bookingRepository.cancelBooking(bookingId, userId);
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }
}
