import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import 'dart:convert';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isTeacher => user?.isTeacher ?? false;
  bool get isStudent => user?.isStudent ?? false;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    _loadUserFromStorage();
  }

  // Load user from storage on app start
  Future<void> _loadUserFromStorage() async {
    try {
      final userData = await SecureStorage.getUserData();
      if (userData != null) {
        final userJson = json.decode(userData) as Map<String, dynamic>;
        state = state.copyWith(user: User.fromJson(userJson));
      }
    } catch (e) {
      // Ignore errors when loading from storage
    }
  }

  // Login - returns User on success, null on failure
  Future<User?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _apiClient.post(
        AppConstants.authLogin,
        data: request.toJson(),
      );

      // Debug: Print response
      print('Login response: ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user data
      await SecureStorage.saveToken(authResponse.accessToken);
      await SecureStorage.saveUserData(json.encode(authResponse.user.toJson()));

      state = state.copyWith(
        user: authResponse.user,
        isLoading: false,
        error: null,
      );

      print('Login successful, user: ${authResponse.user.email}, role: ${authResponse.user.role}');
      return authResponse.user;
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Login failed. Please try again.';
      
      if (e is DioException) {
        // Handle connection errors
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout ||
            e.message?.contains('Connection refused') == true ||
            e.message?.contains('Failed host lookup') == true) {
          errorMessage = 'Cannot connect to server. Please check:\n'
              '1. Backend is running (uvicorn app.main:app --host 0.0.0.0 --port 8000)\n'
              '2. IP address in constants.dart matches your computer\'s IP\n'
              '3. Both devices are on the same network';
        } else if (e.response != null) {
          // Handle HTTP error responses
          final data = e.response!.data;
          print('Error response data: $data');
          if (data is Map<String, dynamic>) {
            if (data.containsKey('detail')) {
              final detail = data['detail'];
              if (detail is String) {
                errorMessage = detail;
              } else if (detail is List && detail.isNotEmpty) {
                errorMessage = detail[0].toString();
              } else {
                errorMessage = detail.toString();
              }
            } else if (data.containsKey('message')) {
              errorMessage = data['message'].toString();
            }
          } else if (data is String) {
            errorMessage = data;
          }
        } else {
          // Other DioException types
          errorMessage = e.message ?? 'Connection error. Please check your internet.';
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      print('Final error message: $errorMessage');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return null;
    }
  }

  // Register - returns User on success, null on failure
  Future<User?> register(String email, String password, String name, String role) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      final response = await _apiClient.post(
        AppConstants.authRegister,
        data: request.toJson(),
      );

      // Debug: Print response
      print('Register response: ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user data
      await SecureStorage.saveToken(authResponse.accessToken);
      await SecureStorage.saveUserData(json.encode(authResponse.user.toJson()));

      state = state.copyWith(
        user: authResponse.user,
        isLoading: false,
        error: null,
      );

      print('Registration successful, user: ${authResponse.user.email}, role: ${authResponse.user.role}');
      return authResponse.user;
    } catch (e, stackTrace) {
      print('Register error: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Registration failed. Please try again.';
      
      if (e is DioException) {
        // Handle connection errors
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout ||
            e.message?.contains('Connection refused') == true ||
            e.message?.contains('Failed host lookup') == true) {
          errorMessage = 'Cannot connect to server. Please check:\n'
              '1. Backend is running (uvicorn app.main:app --host 0.0.0.0 --port 8000)\n'
              '2. IP address in constants.dart matches your computer\'s IP\n'
              '3. Both devices are on the same network';
        } else if (e.response != null) {
          // Handle HTTP error responses
          final data = e.response!.data;
          print('Error response data: $data');
          if (data is Map<String, dynamic>) {
            if (data.containsKey('detail')) {
              final detail = data['detail'];
              if (detail is String) {
                errorMessage = detail;
              } else if (detail is List && detail.isNotEmpty) {
                errorMessage = detail[0].toString();
              } else {
                errorMessage = detail.toString();
              }
            } else if (data.containsKey('message')) {
              errorMessage = data['message'].toString();
            }
          } else if (data is String) {
            errorMessage = data;
          }
        } else {
          // Other DioException types
          errorMessage = e.message ?? 'Connection error. Please check your internet.';
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      print('Final error message: $errorMessage');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return null;
    }
  }

  // Get current user (refresh from API)
  Future<void> getCurrentUser() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get(AppConstants.authMe);
      final user = User.fromJson(response.data);
      
      await SecureStorage.saveUserData(json.encode(user.toJson()));
      
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

