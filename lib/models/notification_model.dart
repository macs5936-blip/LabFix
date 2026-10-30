import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Notificación para alertas en tiempo real en LabFix
/// Permite alertar a un usuario específico o a todos los técnicos ('TECHNICIAN')
class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    required this.recipientId, // UID específico o 'TECHNICIAN'
    required this.title,
    required this.body,
    this.reportId,
    this.isRead = false,
    this.createdAt,
  });

  final String notificationId;
  final String recipientId;
  final String title;
  final String body;
  final String? reportId;
  final bool isRead;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'reportId': reportId,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return NotificationModel(
      notificationId: docId ?? (map['notificationId'] as String? ?? ''),
      recipientId: map['recipientId'] as String? ?? 'TECHNICIAN',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      reportId: map['reportId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  NotificationModel copyWith({
    String? notificationId,
    String? recipientId,
    String? title,
    String? body,
    String? reportId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      body: body ?? this.body,
      reportId: reportId ?? this.reportId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

