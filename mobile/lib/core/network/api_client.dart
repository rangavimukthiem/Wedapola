import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

// Override for local development with:
// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://wedapola.ekafy.com/api',
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  
  final dio = Dio(BaseOptions(
    baseUrl: _apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Inject JWT token if available
      final token = await storage.read(key: 'access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      // Handle 401 Unauthorized (e.g. attempt to refresh token, or log out user)
      if (e.response?.statusCode == 401) {
        // Here we could implement the logic to call the refresh token endpoint.
        // For MVP, we might just clear the token and force re-login.
      }
      return handler.next(e);
    },
  ));

  return dio;
});
