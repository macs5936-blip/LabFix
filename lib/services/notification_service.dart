import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/report_model.dart';

/// Servicio de Notificaciones en tiempo real para LabFix (ESPOCH)
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  /// Crea automáticamente un documento en la colección 'notifications' de Firestore
  /// cada vez que un estudiante registre un nuevo reporte.
  Future<String> sendNotificationToTechnicians(ReportModel report) async {
    final docRef = _notificationsRef.doc();
    final notification = NotificationModel(
      notificationId: docRef.id,
      recipientId: 'TECHNICIAN',
      title: 'Nueva incidencia en ${report.laboratory}',
      body: '${report.userName} reportó: "${report.description}" (Urgencia: ${report.urgency})',
      reportId: report.reportId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(notification.toMap());
    return docRef.id;
  }

  /// Envía una notificación directa a un usuario por su UID (ej. cuando su ticket fue resuelto o actualizado)
  Future<String> sendNotificationToUser({
    required String recipientUid,
    required String title,
    required String body,
    String? reportId,
  }) async {
    final docRef = _notificationsRef.doc();
    final notification = NotificationModel(
      notificationId: docRef.id,
      recipientId: recipientUid,
      title: title,
      body: body,
      reportId: reportId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(notification.toMap());
    return docRef.id;
  }

  /// Retorna un Stream con las alertas no leídas para el panel del técnico.
  /// Incluye notificaciones dirigidas al rol global 'TECHNICIAN' o a su ID personal.
  Stream<List<NotificationModel>> getTechnicianNotifications(String techId) {
    return _notificationsRef
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), docId: doc.id))
          .where((notif) =>
              notif.recipientId == 'TECHNICIAN' ||
              notif.recipientId == techId)
          .toList();

      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Retorna todas las notificaciones recibidas por un usuario específico (leídas o no)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationsRef
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), docId: doc.id))
          .toList();

      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Retorna las notificaciones para el estudiante (específicas para su UID o avisos generales)
  Stream<List<NotificationModel>> getStudentNotifications(String userId) {
    return _notificationsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), docId: doc.id))
          .where((notif) =>
              notif.recipientId == userId ||
              notif.recipientId == 'STUDENT' ||
              notif.recipientId == 'ALL')
          .toList();

      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Cambia el estado de la notificación a leída
  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marca todas las notificaciones de un usuario (o broadcast) como leídas
  Future<void> markAllAsRead(String recipientId) async {
    final query = await _notificationsRef.where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    var count = 0;

    for (final doc in query.docs) {
      final rec = doc.data()['recipientId'];
      if (rec == recipientId || rec == 'STUDENT' || rec == 'ALL' || recipientId.isEmpty) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}

