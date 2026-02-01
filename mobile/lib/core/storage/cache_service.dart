import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static Future<void> setJson(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(value);
    await prefs.setString(key, encoded);
    await prefs.setString('${key}_ts', DateTime.now().toIso8601String());
  }

  static Future<dynamic> getJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return json.decode(raw);
  }

  static Future<DateTime?> getTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${key}_ts');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
