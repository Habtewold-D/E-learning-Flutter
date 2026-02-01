import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../auth/models/user_model.dart';
import '../models/admin_stats_model.dart';
import '../models/admin_analytics_model.dart';
import '../models/admin_trends_model.dart';

class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  Future<AdminStats> fetchStats() async {
    try {
      final response = await _apiClient.get('/admin/stats');
      return AdminStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AdminAnalytics> fetchAnalytics() async {
    try {
      final response = await _apiClient.get('/admin/analytics');
      return AdminAnalytics.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AdminTrends> fetchTrends({required String period}) async {
    try {
      final response = await _apiClient.get('/admin/analytics/trends', queryParameters: {
        'period': period,
      });
      return AdminTrends.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<User>> fetchTeachers() async {
    try {
      final response = await _apiClient.get('/admin/teachers');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
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
