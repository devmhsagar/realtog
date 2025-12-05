import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
        data: {
          'emailOrPhone': emailOrPhone,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;
        
        // Store token in secure storage
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _storage.write(
            key: 'access_token',
            value: token,
          );
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
        if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
          errorMessage = errorData['message'] as String;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Logout - clear token
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }
}

