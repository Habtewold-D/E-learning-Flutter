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
  bool get isAdmin => user?.isAdmin ?? false;

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


      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user data
      await SecureStorage.saveToken(authResponse.accessToken);
      await SecureStorage.saveUserData(json.encode(authResponse.user.toJson()));

      state = state.copyWith(
        user: authResponse.user,
        isLoading: false,
        error: null,
      );

      return authResponse.user;
    } catch (e, stackTrace) {
      
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


      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user data
      await SecureStorage.saveToken(authResponse.accessToken);
      await SecureStorage.saveUserData(json.encode(authResponse.user.toJson()));

      state = state.copyWith(
        user: authResponse.user,
        isLoading: false,
        error: null,
      );

      return authResponse.user;
    } catch (e, stackTrace) {
      
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

  // Update profile (name/email only)
  Future<User?> updateProfile({
    String? name,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.patch(
        AppConstants.authMe,
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
        },
      );

      final updatedUser = User.fromJson(response.data as Map<String, dynamic>);
      await SecureStorage.saveUserData(json.encode(updatedUser.toJson()));

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );

      return updatedUser;
    } catch (e) {
      String errorMessage = 'Update failed. Please try again.';
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else if (data is String) {
          errorMessage = data;
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return null;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiClient.post(
        AppConstants.authChangePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      String errorMessage = 'Password update failed. Please try again.';
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else if (data is String) {
          errorMessage = data;
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

