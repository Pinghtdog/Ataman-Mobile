import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/base_repository.dart';
import '../models/notification_model.dart';

class NotificationRepository extends BaseRepository {
  Future<List<NotificationModel>> getNotifications() async {
    return safeCall(() async {
      final response = await supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    return safeCall(() async {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    });
  }

  Future<void> markAllAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    return safeCall(() async {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    });
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    return safeCall(() async {
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
      });
    });
  }

  Stream<List<NotificationModel>> subscribeToNotifications() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }
}
