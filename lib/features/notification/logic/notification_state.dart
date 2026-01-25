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
  final NotificationType filter;

  const NotificationLoaded({
    required this.notifications,
    this.filter = NotificationType.general, // Using general as 'all' or default
  });

  List<NotificationModel> get filteredNotifications {
    // In a real app, 'general' might mean 'all' in the UI
    // For now, let's assume if we want to filter, we'd pass a specific type
    return notifications; 
  }

  @override
  List<Object?> get props => [notifications, filter];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
