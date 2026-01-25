import 'package:equatable/equatable.dart';

enum NotificationType {
  emergency,
  booking,
  telemedicine,
  general,
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      type: _parseType(json['type']),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type.name,
      'data': data,
    };
  }

  static NotificationType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'emergency':
        return NotificationType.emergency;
      case 'booking':
        return NotificationType.booking;
      case 'telemedicine':
        return NotificationType.telemedicine;
      default:
        return NotificationType.general;
    }
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
      data: data,
    );
  }

  @override
  List<Object?> get props => [id, title, body, createdAt, isRead, type, data];
}
