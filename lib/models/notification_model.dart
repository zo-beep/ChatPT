import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String recipientId;
  final DateTime timestamp;
  final String status;
  final Map<String, dynamic> additionalData;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipientId,
    required this.timestamp,
    required this.status,
    this.additionalData = const {},
    this.readAt,
  });

  // Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      recipientId: data['recipient_id'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'unread',
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'recipient_id': recipientId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'additionalData': additionalData,
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
    };
  }

  // Copy with method
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? recipientId,
    DateTime? timestamp,
    String? status,
    Map<String, dynamic>? additionalData,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      recipientId: recipientId ?? this.recipientId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      additionalData: additionalData ?? this.additionalData,
      readAt: readAt ?? this.readAt,
    );
  }

  // Check if notification is unread
  bool get isUnread => status == 'unread';

  // Check if notification is read
  bool get isRead => status == 'read';

  // Get notification type icon
  String get typeIcon {
    switch (type) {
      case 'reminder':
        return '⏰';
      case 'assignment':
        return '📋';
      case 'general':
        return '📢';
      default:
        return '📢';
    }
  }

  // Get notification type color
  String get typeColor {
    switch (type) {
      case 'reminder':
        return '#FF9800'; // Orange
      case 'assignment':
        return '#2196F3'; // Blue
      case 'general':
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

