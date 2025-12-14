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

  /// Sign in with Google and return the ID token
  /// Returns Either<String error, String token>
  Future<Either<String, String>> signInWithGoogle() async {
    try {
      // Get the singleton GoogleSignIn instance
      // Note: initialize() should be called once at app startup (in main.dart)
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Authenticate the user (this replaces the old signIn method)
      GoogleSignInAccount googleUser;
      try {
        googleUser = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        debugPrint('Authentication failed: ${e.code} - ${e.description}');
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return const Left('Google sign in was cancelled');
        }
        rethrow;
      }

      // Get the ID token from authentication
      final GoogleSignInAuthentication auth = googleUser.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('Warning: ID token is missing after authentication');
        return const Left('Failed to get ID token from Google');
      }

      debugPrint("ID token retrieved successfully (length: ${idToken.length})");
      // Print id token in the console
      // _printLongString(idToken, label: 'ID Token');

      // Make POST API call with the ID token
      try {
        final response = await _dio.post(
          ApiConstants.googleAuthUrlById,
          data: {'idToken': idToken},
        );

        // Print the response in console
        debugPrint('Google Auth API Response:');
        debugPrint('Status Code: ${response.statusCode}');
        if (response.data != null) {
          _printLongString(response.data.toString(), label: 'Response Data');
        } else {
          debugPrint('Response Data: null');
        }
      } catch (e) {
        debugPrint('Error calling Google Auth API: $e');
        if (e is DioException && e.response != null) {
          debugPrint('Error Response Status: ${e.response?.statusCode}');
          if (e.response?.data != null) {
            _printLongString(
              e.response!.data.toString(),
              label: 'Error Response Data',
            );
          }
        }
      }

      // Return the ID token
      // API call will be made with this ID token
      return Right(idToken);
    } on GoogleSignInException catch (e) {
      // Handle any other Google Sign In exceptions
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Left('Google sign in was cancelled');
      }
      if (e.code == GoogleSignInExceptionCode.interrupted) {
        return const Left('Google sign in was interrupted');
      }
      return Left('Google sign in failed: ${e.description ?? e.toString()}');
    } catch (e, stackTrace) {
      debugPrint('Unexpected Google sign in error: $e');
      return Left('Google sign in failed: ${e.toString()}');
    }
  }
}
