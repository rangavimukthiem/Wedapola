import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService(this._dio);

  final Dio _dio;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Future<void> initializeForWorker() async {
    if (_initialized || kIsWeb || Firebase.apps.isEmpty) return;
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;
      if (!await messaging.isSupported()) return;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notifications are disabled for this device.');
        return;
      }

      final token = await messaging.getToken();
      if (token != null) await _registerToken(token);

      _tokenSubscription = messaging.onTokenRefresh.listen((newToken) {
        unawaited(_registerToken(newToken));
      });
      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground push received: ${message.messageId ?? 'no id'}');
      });
    } catch (error) {
      debugPrint('Could not initialize worker push notifications: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    final deviceType = defaultTargetPlatform == TargetPlatform.iOS
        ? 'IOS'
        : 'ANDROID';
    try {
      await _dio.post(
        '/kyc/fcm-token',
        data: {'fcmToken': token, 'deviceType': deviceType},
      );
      debugPrint('Worker push token registered with Wedapola API.');
    } on DioException catch (error) {
      debugPrint(
        'Could not register push token (${error.response?.statusCode ?? 'network error'}).',
      );
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
  }
}
