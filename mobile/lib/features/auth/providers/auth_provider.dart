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

  // Login
  Future<bool> login(String email, String password) async {
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
      );

      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  // Register
  Future<bool> register(String email, String password, String name, String role) async {
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
      );

      return true;
    } catch (e) {
      String errorMessage = 'An error occurred';
      if (e is DioException) {
        // Extract error from DioException
        if (e.response != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else {
            errorMessage = e.message ?? 'An error occurred';
          }
        } else {
          errorMessage = e.message ?? 'Connection error. Please check your internet.';
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
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

