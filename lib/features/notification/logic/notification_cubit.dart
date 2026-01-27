import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription? _subscription;

  NotificationCubit({required NotificationRepository repository})
      : _repository = repository,
        super(NotificationInitial());

  void loadNotifications() {
    emit(NotificationLoading());
    _subscription?.cancel();
    
    _subscription = _repository.subscribeToNotifications().listen(
      (notifications) {
        if (state is NotificationLoaded) {
          emit((state as NotificationLoaded).copyWith(notifications: notifications));
        } else {
          emit(NotificationLoaded(notifications: notifications));
        }
      },
      onError: (error) {
        emit(NotificationError(error.toString()));
      },
    );
  }

  void setFilter(String filter) {
    if (state is NotificationLoaded) {
      emit((state as NotificationLoaded).copyWith(selectedFilter: filter));
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
    } catch (e) {
      // Optional: handle error
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
    } catch (e) {
      // Optional: handle error
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
