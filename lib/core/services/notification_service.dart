import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Function(Map<String, dynamic>)? _onForegroundNotification;
  Function(Map<String, dynamic>)? _onBackgroundNotification;

  NotificationService._internal();

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize({
    Function(Map<String, dynamic>)? onForegroundNotification,
    Function(Map<String, dynamic>)? onBackgroundNotification,
  }) async {
    _onForegroundNotification = onForegroundNotification;
    _onBackgroundNotification = onBackgroundNotification;

    // Request permission for iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (kDebugMode) {
      print('[NotificationService] Permission status: ${settings.authorizationStatus}');
    }

    // Get token
    final token = await _getToken();
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle when app is terminated and opened from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    if (kDebugMode) {
      print('[NotificationService] Initialized with token: $token');
    }
  }

  /// Get and save FCM token
  Future<String?> _getToken() async {
    try {
      final token = await _messaging.getToken();
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('[NotificationService] Token refreshed: $newToken');
        }
      });

      return token;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error getting token: $e');
      }
      return null;
    }
  }

  /// Save token to Firestore
  Future<void> _saveTokenToFirestore(String token, String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'tokenUpdatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error saving token: $e');
      }
    }
  }

  /// Get current user ID from Firebase Auth
  Future<String?> _getCurrentUserId() async {
    try {
      final auth = await _firestore.collection('users')
          .where('isCurrentUser', isEqualTo: true)
          .limit(1)
          .get();
      
      if (auth.docs.isNotEmpty) {
        return auth.docs.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save token with user ID (call after login)
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token, userId);
        if (kDebugMode) {
          print('[NotificationService] Token saved for user: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error saving token for user: $e');
      }
    }
  }

  /// Handle foreground messages (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationService] Foreground message: ${message.notification?.title}');
    }

    if (_onForegroundNotification != null && message.data.isNotEmpty) {
      _onForegroundNotification!(message.data);
    }
  }

  /// Handle background messages (app is in background)
  void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationService] Background message: ${message.notification?.title}');
    }

    if (_onBackgroundNotification != null && message.data.isNotEmpty) {
      _onBackgroundNotification!(message.data);
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('[NotificationService] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('[NotificationService] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error unsubscribing from topic: $e');
      }
    }
  }

  /// Delete token (for logout)
  Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _messaging.deleteToken();
        
        // Also remove from Firestore if we have user ID
        final userId = await _getCurrentUserId();
        if (userId != null) {
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': FieldValue.delete(),
          });
        }
        
        if (kDebugMode) {
          print('[NotificationService] Token deleted');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error deleting token: $e');
      }
    }
  }
}