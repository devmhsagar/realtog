import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import '../constants/api_constants.dart';
import 'http_services.dart';
import 'local_storage_service.dart';

class AuthService {
  final Dio _dio = DioService().client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalStorageService _localStorage = LocalStorageService();

  /// Helper method to print long strings in chunks
  /// Flutter's debugPrint has a character limit (~1000 chars)
  void _printLongString(String message, {String label = ''}) {
    const int chunkSize = 800; // Print in chunks of 800 characters
    if (message.length <= chunkSize) {
      if (label.isNotEmpty) {
        debugPrint('$label: $message');
      } else {
        debugPrint(message);
      }
      return;
    }

    if (label.isNotEmpty) {
      debugPrint('$label (${message.length} chars, split into chunks):');
    } else {
      debugPrint('Long string (${message.length} chars, split into chunks):');
    }

    for (int i = 0; i < message.length; i += chunkSize) {
      final int end = (i + chunkSize < message.length)
          ? i + chunkSize
          : message.length;
      final String chunk = message.substring(i, end);
      debugPrint('[$i-$end]: $chunk');
    }
  }

  /// Reusable function to handle auth API response
  /// Extracts token, stores it, and parses user from response
  Future<Either<String, UserModel>> _handleAuthResponse(
    Response<dynamic> response,
  ) async {
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
      return const Left('Authentication failed. Please try again.');
    }
  }

  /// Helper function to extract error message from DioException
  String _extractErrorMessage(DioException e) {
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

    return errorMessage;
  }

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

      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      return Left(_extractErrorMessage(e));
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

  /// Logout - clear token and all local storage data
  Future<void> logout() async {
    // Clear secure storage (token)
    await _storage.delete(key: 'access_token');
    // Clear all SharedPreferences data (including selected images)
    await _localStorage.clearAll();
  }

  /// Sign in with Google and return the user
  /// Returns Either<String error, UserModel>
  /// Create platform-specific GoogleSignIn instances
  GoogleSignIn get _googleSignIn {
    if (Platform.isIOS) {
      // iOS configuration: needs clientId, serverClientId is optional
      return GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId:
            '363337467133-ljjgk6n3204csqm7skqf6tqfcqv7ufvh.apps.googleusercontent.com',
      );
    } else {
      // Android configuration: needs serverClientId to get full ID token with all claims
      return GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '363337467133-0ijfok2qta8nb5ma7o98ho2pefrhvsps.apps.googleusercontent.com',
      );
    }
  }

  Future<Either<String, UserModel>> signInWithGoogle() async {
    try {
      GoogleSignInAccount? user;
      try {
        // On Android, sign out first to ensure we get a fresh token with all claims
        // This is important because cached tokens might not include all claims
        if (Platform.isAndroid) {
          await _googleSignIn.signOut();
        }
        user = await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        return Left('Google sign in failed: ${e.message ?? e.code}');
      } catch (e) {
        debugPrint('Error during Google Sign-In: $e');
        return Left('Google sign in failed: ${e.toString()}');
      }

      if (user == null) {
        // User cancelled
        return const Left('Google sign in was cancelled');
      }

      // Request authentication - this will use serverClientId on Android to get full ID token
      final GoogleSignInAuthentication auth = await user.authentication;

      // Get the ID token
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return const Left(
          'Failed to get ID token from Google. Please check serverClientId configuration.',
        );
      }

      // Make Auth API call with the ID token
      try {
        final response = await _dio.post(
          ApiConstants.googleAuthUrlById,
          data: {'idToken': idToken},
        );

        // Use the same reusable function to handle the response
        return await _handleAuthResponse(response);
      } on DioException catch (e) {
        if (e.response?.data != null) {
          debugPrint('Error Response: ${e.response!.data}');
          // If it's a map, try to extract the message
          if (e.response!.data is Map<String, dynamic>) {
            final errorData = e.response!.data as Map<String, dynamic>;
            if (errorData.containsKey('message')) {
              return Left(errorData['message'] as String);
            }
          }
        }
        return Left(_extractErrorMessage(e));
      } catch (e) {
        debugPrint('Error calling Google Auth API: $e');
        return Left('Google sign in failed: ${e.toString()}');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return Left('Google sign in failed: ${e.toString()}');
    }
  }

  /// Forgot password - send OTP to email
  Future<Either<String, String>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPasswordUrl,
        data: {'email': email},
      );

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
              responseData['message'] as String? ?? 'Failed to send OTP';
          return Left(message);
        }

        // Extract email from response data
        final data = responseData['data'] as Map<String, dynamic>;
        final emailFromResponse = data['email'] as String? ?? email;

        return Right(emailFromResponse);
      } else {
        return const Left('Failed to send OTP. Please try again.');
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

  /// Verify OTP - verify the OTP code sent to email
  Future<Either<String, String>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtpUrl,
        data: {'email': email, 'code': code},
      );

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
              responseData['message'] as String? ?? 'Failed to verify OTP';
          return Left(message);
        }

        // Extract email from response data
        final data = responseData['data'] as Map<String, dynamic>;
        final emailFromResponse = data['email'] as String? ?? email;
        final verified = data['verified'] as bool? ?? false;

        if (!verified) {
          return const Left('OTP verification failed');
        }

        return Right(emailFromResponse);
      } else {
        return const Left('Failed to verify OTP. Please try again.');
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

  /// Reset password - reset password with OTP
  Future<Either<String, String>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPasswordUrl,
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      );

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
              responseData['message'] as String? ?? 'Failed to reset password';
          return Left(message);
        }

        // Extract email from response data
        final data = responseData['data'] as Map<String, dynamic>;
        final emailFromResponse = data['email'] as String? ?? email;

        return Right(emailFromResponse);
      } else {
        return const Left('Failed to reset password. Please try again.');
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

  /// Resend OTP - resend OTP to email
  Future<Either<String, String>> resendOtp({required String email}) async {
    try {
      final response = await _dio.post(
        ApiConstants.resendOtpUrl,
        data: {'email': email},
      );

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
              responseData['message'] as String? ?? 'Failed to resend OTP';
          return Left(message);
        }

        // Extract email from response data
        final data = responseData['data'] as Map<String, dynamic>;
        final emailFromResponse = data['email'] as String? ?? email;

        return Right(emailFromResponse);
      } else {
        return const Left('Failed to resend OTP. Please try again.');
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
}
