import 'package:equatable/equatable.dart';
import '../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final String selectedFilter;

  const NotificationLoaded({
    required this.notifications,
    this.selectedFilter = 'All',
  });

  List<NotificationModel> get filteredNotifications {
    if (selectedFilter == 'All') return notifications;
    if (selectedFilter == 'Emergency') {
      return notifications.where((n) => n.type == NotificationType.emergency).toList();
    }
    if (selectedFilter == 'Bookings') {
      return notifications.where((n) => n.type == NotificationType.booking).toList();
    }
    return notifications;
  }

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    String? selectedFilter,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [notifications, selectedFilter];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
