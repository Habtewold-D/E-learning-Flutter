import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Token Management
  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // User Data Management
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: AppConstants.userKey, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: AppConstants.userKey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: AppConstants.userKey);
  }

  // Push Token Management
  static Future<void> savePushToken(String token) async {
    await _storage.write(key: AppConstants.pushTokenKey, value: token);
  }

  static Future<String?> getPushToken() async {
    return await _storage.read(key: AppConstants.pushTokenKey);
  }

  static Future<void> deletePushToken() async {
    await _storage.delete(key: AppConstants.pushTokenKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}


