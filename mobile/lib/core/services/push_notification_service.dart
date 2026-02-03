import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api/api_client.dart';
import '../storage/secure_storage.dart';
import '../utils/constants.dart';

class PushNotificationService {
  static bool _initialized = false;

  static Future<void> registerToken(ApiClient apiClient) async {
    if (kIsWeb) return;

    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {
      // Ignore permission errors
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final saved = await SecureStorage.getPushToken();
    if (saved == token && _initialized) {
      return;
    }

    final deviceType = Platform.isAndroid ? 'android' : 'ios';

    await apiClient.post(
      AppConstants.notificationTokens,
      data: {
        'token': token,
        'device_type': deviceType,
      },
    );

    await SecureStorage.savePushToken(token);

    if (!_initialized) {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;
        try {
          await apiClient.post(
            AppConstants.notificationTokens,
            data: {
              'token': newToken,
              'device_type': deviceType,
            },
          );
          await SecureStorage.savePushToken(newToken);
        } catch (_) {
          // Ignore refresh errors
        }
      });
      _initialized = true;
    }
  }

  static Future<void> unregisterToken(ApiClient apiClient) async {
    if (kIsWeb) return;

    final token = await SecureStorage.getPushToken();
    if (token == null || token.isEmpty) return;

    try {
      await apiClient.delete(
        AppConstants.notificationTokens,
        data: {'token': token},
      );
    } catch (_) {
      // Ignore unregister errors
    }

    await SecureStorage.deletePushToken();
  }
}
