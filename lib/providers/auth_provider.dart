import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

/// Authentication state model
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final UserModel? user;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    UserModel? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Authentication state notifier
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    // Check for existing token on initialization
    _checkAuthStatus();
    // Return initial state with loading true while checking
    return const AuthState(isLoading: true);
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    final isAuthenticated = await _authService.isAuthenticated();
    state = state.copyWith(isAuthenticated: isAuthenticated, isLoading: false);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  Future<void> login(String emailOrPhone, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );

    result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
      },
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // Clear previous error and set loading
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    result.fold(
      (error) {
        // Set error with loading false
        state = state.copyWith(isLoading: false, error: error);
      },
      (user) {
        // For registration, we don't set isAuthenticated to true
        // User needs to login after registration
        state = state.copyWith(isLoading: false, user: user, error: null);
      },
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }
}

/// Authentication provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Profile data provider - fetches current user data
final profileDataProvider = FutureProvider<UserModel>((ref) async {
  final authService = ref.read(authServiceProvider);
  final result = await authService.getCurrentUser();
  
  return result.fold(
    (error) => throw Exception(error),
    (user) => user,
  );
});
