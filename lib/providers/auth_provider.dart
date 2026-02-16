import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

/// Authentication state model
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  /// Fully authenticated user (after OTP)
  final UserModel? user;

  /// User created but not verified yet
  final UserModel? pendingUser;

  /// Token from register API; saved only after OTP verification
  final String? pendingRegisterToken;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.pendingUser,
    this.pendingRegisterToken,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    UserModel? user,
    UserModel? pendingUser,
    String? pendingRegisterToken,
    bool clearPendingRegisterToken = false,
    bool clearPendingUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
      pendingUser:
      clearPendingUser ? null : (pendingUser ?? this.pendingUser),
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
        // 🔴 VERY IMPORTANT:
        // Block login if user email/phone is not verified
        if (user.emailVerified == false) {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            error: 'Please verify your email first',
          );
          return;
        }

        // ✅ Verified user → allow login
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

    // 🔥 VERY IMPORTANT FIX
    // Clear any existing login session before registering
    await _authService.logout();

    state = state.copyWith(
      isLoading: true,
      error: null,
      isAuthenticated: false,
    );


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
        // IMPORTANT:
        // Registration ≠ Authentication
        state = state.copyWith(
          isLoading: false,
          pendingUser: registerResult.user,
          pendingRegisterToken: registerResult.token,
          isAuthenticated: false, // 🔒 force false until OTP verified
          error: null,
        );
      },
    );
  }

  /// Call after OTP verification in registration flow: save token and mark authenticated.
 Future<void> completeRegistrationAfterOtp() async {
    final token = state.pendingRegisterToken;
    final pendingUser = state.pendingUser;

    if (token == null || token.isEmpty || pendingUser == null) return;

    // Save token ONLY after OTP success
    await _authService.saveToken(token);

    state = state.copyWith(
      isAuthenticated: true,
      user: pendingUser,
      clearPendingRegisterToken: true,
      clearPendingUser: true,
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
        // 🔴 Block login if email not verified
        if (user.emailVerified == false) {
          state = state.copyWith(
            isLoading: false,
            error: 'Please verify your email first',
          );
          return;
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
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
