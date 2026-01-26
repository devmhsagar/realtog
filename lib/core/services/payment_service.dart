import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../constants/api_constants.dart';
import 'http_services.dart';

class PaymentService {
  final Dio _dio = DioService().client;

  /// Create a checkout session with plan ID and image paths
  Future<Either<String, Map<String, dynamic>>> createCheckoutSession({
    required String planId,
    required List<String> images,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.paymentUrl,
        data: {
          'plan_id': planId,
          'images': images,
        },
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
          final message = responseData['message'] as String? ??
              'Failed to create checkout session';
          return Left(message);
        }

        final data = responseData['data'] as Map<String, dynamic>;
        return Right(data);
      } else {
        return const Left(
          'Failed to create checkout session. Please try again.',
        );
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
