import '../../../core/api/api_client.dart';

class AdminNotificationService {
  final ApiClient _apiClient;

  AdminNotificationService(this._apiClient);

  Future<void> sendNotification({
    required String title,
    required String body,
    required String targetRole,
    required bool sendPush,
    required bool sendInApp,
  }) async {
    await _apiClient.post(
      '/notifications/send',
      data: {
        'title': title,
        'body': body,
        'target_role': targetRole,
        'send_push': sendPush,
        'send_in_app': sendInApp,
      },
    );
  }
}
