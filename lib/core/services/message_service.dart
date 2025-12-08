import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/message_model.dart';
import '../constants/api_constants.dart';
import 'http_services.dart';

class MessageService {
  final Dio _dio = DioService().client;

  /// Get all messages between user and admin
  Future<Either<String, List<MessageModel>>> getMessages() async {
    try {
      final response = await _dio.get(
        ApiConstants.messagesUrl,
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
              responseData['message'] as String? ?? 'Failed to fetch messages';
          return Left(message);
        }

        final data = responseData['data'] as List<dynamic>;
        final messages = data
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Right(messages);
      } else {
        return const Left('Failed to fetch messages. Please try again.');
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

  /// Send a message with optional images
  Future<Either<String, MessageModel>> sendMessage({
    required String message,
    List<XFile>? images,
  }) async {
    try {
      // Create FormData for multipart request
      final formData = FormData();

      // Add message text
      formData.fields.add(MapEntry('message', message));

      // Add images as files if provided
      if (images != null && images.isNotEmpty) {
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
      }

      final response = await _dio.post(
        ApiConstants.messagesUrl,
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
          final errorMessage =
              responseData['message'] as String? ?? 'Failed to send message';
          return Left(errorMessage);
        }

        final data = responseData['data'] as Map<String, dynamic>;
        final sentMessage = MessageModel.fromJson(data);

        return Right(sentMessage);
      } else {
        return const Left('Failed to send message. Please try again.');
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

