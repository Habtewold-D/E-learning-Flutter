import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import '../models/in_app_notification_model.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<List<InAppNotification>> fetchInAppNotifications() async {
    final response = await _apiClient.get(AppConstants.notificationsInApp);
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => InAppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<InAppNotification> markAsRead(int notificationId, bool isRead) async {
    final response = await _apiClient.patch(
      '${AppConstants.notificationsInApp}/$notificationId',
      data: {'is_read': isRead},
    );
    return InAppNotification.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteInAppNotification(int notificationId) async {
    await _apiClient.delete(
      '${AppConstants.notificationsInApp}/$notificationId',
    );
  }

  Future<void> markAllRead() async {
    await _apiClient.patch('${AppConstants.notificationsInApp}/read-all');
  }
}
