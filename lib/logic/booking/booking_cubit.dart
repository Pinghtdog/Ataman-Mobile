import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _bookingRepository;
  StreamSubscription? _bookingsSubscription;

  BookingCubit({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository,
        super(BookingInitial());

  Future<void> createBooking(Booking booking) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.createBooking(booking);
      // After creating, we might want to refresh or rely on the stream
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
