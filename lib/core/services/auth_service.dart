import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import '../constants/api_constants.dart';
import 'http_services.dart';

class AuthService {
  final Dio _dio = DioService().client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Login with email/phone and password
  Future<Either<String, UserModel>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginUrl,
        data: {'emailOrPhone': emailOrPhone, 'password': password},
      );

      // Check for successful status codes (200-299)
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;

        // Store token in secure storage
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'access_token', value: token);
        }

        // Parse user from response
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);

        return Right(user);
      } else {
        return const Left('Login failed. Please try again.');
      }
    } on DioException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';

      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('message')) {
          errorMessage = errorData['message'] as String;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return Left(errorMessage);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Register with name, email, phone, and password
  Future<Either<String, UserModel>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerUrl,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      // Check for successful status codes (200-299)
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Check if registration was successful
        final success = responseData['success'] as bool? ?? false;

        if (!success) {
          // Handle success: false case
          final message =
              responseData['message'] as String? ?? 'Registration failed';
          return Left(message);
        }

        final data = responseData['data'] as Map<String, dynamic>;

        // Parse user from response (don't store token for registration)
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);

        return Right(user);
      } else {
        return const Left('Registration failed. Please try again.');
      }
    } on DioException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';

      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          // Check for success: false response
          if (errorData.containsKey('success') &&
              errorData['success'] == false &&
              errorData.containsKey('message')) {
            errorMessage = errorData['message'] as String;
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'] as String;
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return Left(errorMessage);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }

  /// Get current user data
  Future<Either<String, UserModel>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.currentUserUrl);

      // Check for successful status codes (200-299)
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Check if request was successful
        final success = responseData['success'] as bool? ?? false;

        if (!success) {
          final message =
              responseData['message'] as String? ?? 'Failed to fetch user data';
          return Left(message);
        }

        final data = responseData['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data);

        return Right(user);
      } else {
        return const Left('Failed to fetch user data. Please try again.');
      }
    } on DioException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';

      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('success') &&
              errorData['success'] == false &&
              errorData.containsKey('message')) {
            errorMessage = errorData['message'] as String;
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'] as String;
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return Left(errorMessage);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }

  /// Logout - clear token
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  /// Sign in with Google and return the access token
  /// Returns Either<String error, String token>
  Future<Either<String, String>> signInWithGoogle() async {
    try {
      // Get the singleton GoogleSignIn instance
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Initialize Google Sign In (must be called once before other methods)
      await googleSignIn.initialize();

      // Authenticate the user (this replaces the old signIn method)
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Request authorization for scopes to get access token
      final GoogleSignInClientAuthorization authorization = await googleUser
          .authorizationClient
          .authorizeScopes(['email', 'profile']);

      // Get the access token
      final String accessToken = authorization.accessToken;

      if (accessToken.isEmpty) {
        return const Left('Failed to get access token from Google');
      }

      debugPrint("Access token");
      debugPrint(accessToken);

      // Return the access token
      // The user will make API call with this token later
      return Right(accessToken);
    } on GoogleSignInException catch (e) {
      // Handle Google Sign In specific exceptions
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Left('Google sign in was cancelled');
      }
      return Left('Google sign in failed: ${e.description ?? e.toString()}');
    } catch (e) {
      return Left('Google sign in failed: ${e.toString()}');
    }
  }
}
