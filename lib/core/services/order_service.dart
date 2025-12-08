import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import 'http_services.dart';

class OrderService {
  final Dio _dio = DioService().client;

  /// Create an order with pricing plan ID and images
  Future<Either<String, Map<String, dynamic>>> createOrder({
    required String planId,
    required List<XFile> images,
  }) async {
    try {
      // Create FormData for multipart request
      final formData = FormData();

      // Add plan_id
      formData.fields.add(MapEntry('plan_id', planId));

      // Add images as files
      for (var image in images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              image.path,
              filename: image.name,
            ),
          ),
        );
      }

      final response = await _dio.post(
        ApiConstants.ordersUrl,
        data: formData,
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
              responseData['message'] as String? ?? 'Failed to create order';
          return Left(message);
        }

        final data = responseData['data'] as Map<String, dynamic>;
        return Right(data);
      } else {
        return const Left('Failed to create order. Please try again.');
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
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return Left(errorMessage);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}

