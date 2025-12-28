import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'local_storage_service.dart';

class DioService {
  // Singleton
  static final DioService _instance = DioService._internal();
  factory DioService() => _instance;

  DioService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 100),
        receiveTimeout: const Duration(seconds: 100),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // get token from secure storage
          final token = await _storage.read(key: "access_token");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Clear secure storage (token)
            await _storage.deleteAll();
            // Clear all SharedPreferences data (including selected images)
            await _localStorage.clearAll();
            // TODO: Add navigation to login page if needed
          }
          return handler.next(e);
        },
      ),
    );
  }

  late Dio _dio;
  final _storage = const FlutterSecureStorage();
  final _localStorage = LocalStorageService();

  Dio get client => _dio;
}

// Usage Example
// final dio = DioService().client;

// Future<void> fetchUserProfile() async {
//   try {
//     final response = await dio.get("/user/profile");
//     print(response.data);
//   } catch (e) {
//     print("Error: $e");
//   }
// }
