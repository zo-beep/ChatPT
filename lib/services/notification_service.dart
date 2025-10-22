import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;

  // Initialize FCM and request permissions
  static Future<void> initialize() async {
    try {
      print('Initializing FCM and local notifications...');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted permission for notifications');
        
        // Get FCM token
        await _getFCMToken();
        
        // Set up message handlers
        _setupMessageHandlers();
        
        // Store token in Firestore if user is authenticated
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _storeFCMToken();
        }
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          print('FCM token refreshed: $newToken');
          _fcmToken = newToken;
          _storeFCMToken();
        });
        
      } else {
        print('User declined or has not accepted permission for notifications');
      }
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      print('Local notifications initialized successfully');
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  // Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  // Get FCM token
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('FCM Token obtained: $_fcmToken');
      
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        print('Warning: FCM token is null or empty');
        // Try to get token again after a short delay
        await Future.delayed(const Duration(seconds: 2));
        _fcmToken = await _messaging.getToken();
        print('FCM Token retry: $_fcmToken');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      _fcmToken = null;
    }
  }

  // Store FCM token in Firestore
  static Future<void> _storeFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _fcmToken != null && _fcmToken!.isNotEmpty) {
        print('Storing FCM token for user: ${user.uid}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM token stored successfully in Firestore');
      } else {
        print('Cannot store FCM token: user=${user?.uid}, token=$_fcmToken');
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  // Update FCM token when user logs in
  static Future<void> updateFCMTokenForUser(String userId) async {
    try {
      // Ensure we have a valid token
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        print('No FCM token available, attempting to get one...');
        await _getFCMToken();
      }
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        print('Updating FCM token for user: $userId');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM token updated successfully for user: $userId');
      } else {
        print('Cannot update FCM token: token is null or empty');
      }
    } catch (e) {
      print('Error updating FCM token for user: $e');
    }
  }

  // Set up message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Handle foreground notification display
        _handleForegroundNotification(message);
      }
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
      // Handle notification tap when app is in background
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state via notification');
        print('Message data: ${message.data}');
        _handleNotificationTap(message);
      }
    });
  }

  // Handle foreground notifications
  static void _handleForegroundNotification(RemoteMessage message) {
    print('Foreground notification: ${message.notification?.title}');
    print('Foreground notification body: ${message.notification?.body}');
    
    // Show local notification when app is in foreground
    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification type
    final notificationType = message.data['type'];
    final notificationId = message.data['notificationId'];
    
    print('Notification tapped - Type: $notificationType, ID: $notificationId');
    
    // You can implement navigation logic here based on notification type
    switch (notificationType) {
      case 'reminder':
        // Navigate to reminders screen
        break;
      case 'assignment':
        // Navigate to exercise screen
        break;
      case 'general':
        // Navigate to notifications screen
        break;
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'chatpt_channel',
        'ChatPT Notifications',
        channelDescription: 'Notifications for ChatPT app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      print('Local notification shown: $title');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create notification document in Firestore
      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'recipient_id': recipientId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'additionalData': additionalData ?? {},
      };

      final docRef = await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);

      print('Notification created with ID: ${docRef.id}');
      
      // In a real implementation, you would send the FCM message here
      // This would typically be done via a Cloud Function or your backend
      // For now, we're just storing the notification in Firestore
      
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Get user's notifications
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipient_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadNotificationCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipient_id', isEqualTo: userId)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all notifications as read for user
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipient_id', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .get();

      if (notifications.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        
        for (final doc in notifications.docs) {
          batch.update(doc.reference, {
            'status': 'read',
            'readAt': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        print('Marked ${notifications.docs.length} notifications as read');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Clear all notifications for user
  static Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipient_id', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Get current FCM token
  static String? getFCMToken() {
    return _fcmToken;
  }

  // Refresh FCM token
  static Future<void> refreshFCMToken() async {
    try {
      await _getFCMToken();
      await _storeFCMToken();
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  
  // Handle background notification processing here
  // This function runs when the app is in the background
}
