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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Required for iOS - client ID from Google Cloud Console (iOS OAuth client)
    clientId:
        '363337467133-ljjgk6n3204csqm7skqf6tqfcqv7ufvh.apps.googleusercontent.com',
    // Required for Android to get ID tokens - OAuth 2.0 Web client ID from Google Cloud Console
    // This should be the Web application client ID (not iOS or Android client ID)
    // If you don't have a Web client ID, create one in Google Cloud Console > APIs & Services > Credentials
    serverClientId:
        '363337467133-l24o0nlfvo1f61235mud2nd14a3ub560.apps.googleusercontent.com',
  );

  Future<Either<String, String>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user == null) {
        // User cancelled
        return const Left('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication auth = await user.authentication;

      // Debug information
      debugPrint('Google Sign-In Authentication Details:');
      debugPrint('Name: ${user.displayName}');
      debugPrint('Email: ${user.email}');
      debugPrint('ID: ${user.id}');
      debugPrint(
        'Access Token: ${auth.accessToken != null ? "Present (${auth.accessToken!.length} chars)" : "null"}',
      );
      debugPrint(
        'ID Token: ${auth.idToken != null ? "Present (${auth.idToken!.length} chars)" : "null"}',
      );

      // Get the ID token
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('ERROR: ID token is missing after authentication');
        debugPrint('This usually means:');
        debugPrint('1. For Android: serverClientId is missing or incorrect');
        debugPrint(
          '2. The OAuth 2.0 Web client ID is not configured in GoogleSignIn',
        );
        debugPrint(
          '3. The SHA-1 fingerprint is not registered in Google Cloud Console',
        );
        return const Left(
          'Failed to get ID token from Google. Please check serverClientId configuration.',
        );
      }

      debugPrint('Google Sign-In successful');
      debugPrint('ID Token length: ${idToken.length}');

      // Make Auth API call with the ID token
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
      return Right(idToken);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return Left('Google sign in failed: ${e.toString()}');
    }
  }

  // Future<Either<String, String>> signInWithGoogle() async {
  //   try {
  //     // Get the singleton GoogleSignIn instance
  //     // Note: initialize() should be called once at app startup (in main.dart)
  //     final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  //
  //     // Authenticate the user (this replaces the old signIn method)
  //     GoogleSignInAccount googleUser;
  //     try {
  //       googleUser = await googleSignIn.authenticate();
  //     } on GoogleSignInException catch (e) {
  //       debugPrint('Authentication failed: ${e.code} - ${e.description}');
  //       if (e.code == GoogleSignInExceptionCode.canceled) {
  //         return const Left('Google sign in was cancelled');
  //       }
  //       rethrow;
  //     }
  //
  //     // Get the ID token from authentication
  //     final GoogleSignInAuthentication auth = googleUser.authentication;
  //     final String? idToken = auth.idToken;
  //
  //     if (idToken == null || idToken.isEmpty) {
  //       debugPrint('Warning: ID token is missing after authentication');
  //       return const Left('Failed to get ID token from Google');
  //     }
  //
  //     debugPrint("ID token retrieved successfully (length: ${idToken.length})");
  //     // Print id token in the console
  //     // _printLongString(idToken, label: 'ID Token');
  //
  //     // Make POST API call with the ID token
  //     try {
  //       final response = await _dio.post(
  //         ApiConstants.googleAuthUrlById,
  //         data: {'idToken': idToken},
  //       );
  //
  //       // Print the response in console
  //       debugPrint('Google Auth API Response:');
  //       debugPrint('Status Code: ${response.statusCode}');
  //       if (response.data != null) {
  //         _printLongString(response.data.toString(), label: 'Response Data');
  //       } else {
  //         debugPrint('Response Data: null');
  //       }
  //     } catch (e) {
  //       debugPrint('Error calling Google Auth API: $e');
  //       if (e is DioException && e.response != null) {
  //         debugPrint('Error Response Status: ${e.response?.statusCode}');
  //         if (e.response?.data != null) {
  //           _printLongString(
  //             e.response!.data.toString(),
  //             label: 'Error Response Data',
  //           );
  //         }
  //       }
  //     }
  //
  //     // Return the ID token
  //     // API call will be made with this ID token
  //     return Right(idToken);
  //   } on GoogleSignInException catch (e) {
  //     // Handle any other Google Sign In exceptions
  //     debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
  //     if (e.code == GoogleSignInExceptionCode.canceled) {
  //       return const Left('Google sign in was cancelled');
  //     }
  //     if (e.code == GoogleSignInExceptionCode.interrupted) {
  //       return const Left('Google sign in was interrupted');
  //     }
  //     return Left('Google sign in failed: ${e.description ?? e.toString()}');
  //   } catch (e) {
  //     debugPrint('Unexpected Google sign in error: $e');
  //     return Left('Google sign in failed: ${e.toString()}');
  //   }
  // }

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
