import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../models/pricing_model.dart';
import '../constants/api_constants.dart';
import 'http_services.dart';

class PricingService {
  final Dio _dio = DioService().client;

  /// Get pricing plans
  Future<Either<String, List<PricingModel>>> getPricingPlans() async {
    try {
      final response = await _dio.get(ApiConstants.pricingUrl);

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
              responseData['message'] as String? ?? 'Failed to fetch pricing plans';
          return Left(message);
        }

        final data = responseData['data'] as List<dynamic>;
        final pricingPlans = data
            .map((json) => PricingModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Right(pricingPlans);
      } else {
        return const Left('Failed to fetch pricing plans. Please try again.');
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

  /// Get pricing plan by ID
  Future<Either<String, PricingModel>> getPricingPlanById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.pricingUrl}/$id');

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
              responseData['message'] as String? ?? 'Failed to fetch pricing plan';
          return Left(message);
        }

        final data = responseData['data'] as Map<String, dynamic>;
        final pricingPlan = PricingModel.fromJson(data);

        return Right(pricingPlan);
      } else {
        return const Left('Failed to fetch pricing plan. Please try again.');
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

