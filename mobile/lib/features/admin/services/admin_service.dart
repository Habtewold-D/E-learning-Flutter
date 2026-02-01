import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../auth/models/user_model.dart';
import '../models/admin_stats_model.dart';
import '../models/admin_analytics_model.dart';
import '../models/admin_trends_model.dart';

class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  Future<AdminStats> fetchStats() async {
    const cacheKey = 'cache:admin:stats';
    try {
      final response = await _apiClient.get('/admin/stats');
      await CacheService.setJson(cacheKey, response.data);
      return AdminStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is Map<String, dynamic>) {
        return AdminStats.fromJson(cached);
      }
      throw _handleError(e);
    }
  }

  Future<AdminAnalytics> fetchAnalytics() async {
    const cacheKey = 'cache:admin:analytics';
    try {
      final response = await _apiClient.get('/admin/analytics');
      await CacheService.setJson(cacheKey, response.data);
      return AdminAnalytics.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is Map<String, dynamic>) {
        return AdminAnalytics.fromJson(cached);
      }
      throw _handleError(e);
    }
  }

  Future<AdminTrends> fetchTrends({required String period}) async {
    final cacheKey = 'cache:admin:trends:$period';
    try {
      final response = await _apiClient.get('/admin/analytics/trends', queryParameters: {
        'period': period,
      });
      await CacheService.setJson(cacheKey, response.data);
      return AdminTrends.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is Map<String, dynamic>) {
        return AdminTrends.fromJson(cached);
      }
      throw _handleError(e);
    }
  }

  Future<List<User>> fetchTeachers() async {
    const cacheKey = 'cache:admin:teachers';
    try {
      final response = await _apiClient.get('/admin/teachers');
      final list = response.data as List<dynamic>;
      await CacheService.setJson(cacheKey, list);
      return list
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is List) {
        return cached
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw _handleError(e);
    }
  }

  Future<User> createTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/admin/teachers',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateTeacher({
    required int teacherId,
    String? name,
    String? email,
    String? password,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/admin/teachers/$teacherId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (password != null) 'password': password,
        },
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTeacher(int teacherId) async {
    try {
      await _apiClient.delete('/admin/teachers/$teacherId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return Exception(data['detail'].toString());
      }
      if (data is String) {
        return Exception(data);
      }
    }
    return Exception('Request failed. Please try again.');
  }
}
