import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  final Dio dio;
  final FlutterSecureStorage storage;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // The web implementation needs the OAuth client ID directly. This is
    // the same web client used as the server client ID on mobile.
    clientId: '990301540746-be3j9ku5asfm8tevj4pv2seltmf6rf92.apps.googleusercontent.com',
    serverClientId: '990301540746-r2mfv50lmudr9pto5hgocd70il4vtd0q.apps.googleusercontent.com',
  );


  AuthRepository({required this.dio, required this.storage});

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        throw Exception("Sign in aborted");
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception("Failed to get ID token from Google");
      }

      // Send token to our backend
      final response = await dio.post('/auth/google', data: {
        'token': idToken,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final accessToken = data['tokens']['accessToken'];
        final refreshToken = data['tokens']['refreshToken'];
        
        // Securely store tokens
        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'refresh_token', value: refreshToken);
        
        // Optionally store user info or role
        // ...
      } else {
        throw Exception("Backend authentication failed");
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 400) {
        throw Exception(
          'Google token was rejected. Check that the backend GOOGLE_CLIENT_ID '
          'matches the mobile server client ID.',
        );
      }
      if (e.response == null) {
        throw Exception(
          'Cannot reach the Wedapola API. Check that it is running and that '
          'API_BASE_URL points to the correct host for this device.',
        );
      }
      throw Exception('Wedapola API error (${status ?? 'unknown'}).');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'access_token');
    return token != null;
  }
}
