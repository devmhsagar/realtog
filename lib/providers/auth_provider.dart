import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

/// Authentication state model
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final UserModel? user;

  /// Token from register API; saved to storage after OTP verification.
  final String? pendingRegisterToken;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.pendingRegisterToken,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    UserModel? user,
    String? pendingRegisterToken,
    bool clearPendingRegisterToken = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
      pendingRegisterToken: clearPendingRegisterToken
          ? null
          : (pendingRegisterToken ?? this.pendingRegisterToken),
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
        // Providers watching authNotifierProvider will automatically invalidate
        // and refetch when auth state changes
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
        state = state.copyWith(isLoading: false, error: error);
      },
      (registerResult) {
        // Store user and token until OTP is verified; then completeRegistrationAfterOtp saves token
        state = state.copyWith(
          isLoading: false,
          user: registerResult.user,
          pendingRegisterToken: registerResult.token,
          error: null,
        );
      },
    );
  }

  /// Call after OTP verification in registration flow: save token and mark authenticated.
  Future<void> completeRegistrationAfterOtp() async {
    final token = state.pendingRegisterToken;
    if (token == null || token.isEmpty) return;
    await _authService.saveToken(token);
    state = state.copyWith(
      isAuthenticated: true,
      clearPendingRegisterToken: true,
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    // Set auth state to unauthenticated
    // Providers watching authNotifierProvider will automatically invalidate
    // and clear when auth state changes
    state = const AuthState();
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.signInWithGoogle();

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
        // Providers watching authNotifierProvider will automatically invalidate
        // and refetch when auth state changes
      },
    );
  }
}

/// Authentication provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Profile data provider - fetches current user data
/// Automatically invalidates when auth state changes
final profileDataProvider = FutureProvider<UserModel>((ref) async {
  // Watch auth state to automatically invalidate when auth changes
  final authState = ref.watch(authNotifierProvider);

  // Only fetch if authenticated
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }

  final authService = ref.read(authServiceProvider);
  final result = await authService.getCurrentUser();

  return result.fold((error) => throw Exception(error), (user) => user);
});
