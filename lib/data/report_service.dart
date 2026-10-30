import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'report_model.dart';

class ReportService {
  ReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchMyReports() {
    final user = _requireUser();
    return _reports
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchAllReports() {
    _requireUser();
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<String> createReport({
    required String building,
    required String laboratory,
    required String machine,
    required Urgency urgency,
    required String description,
    String? category,
    bool hasEvidence = false,
  }) async {
    final user = _requireUser();
    final userProfile = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    final report = _reports.doc();

    await report.set({
      'createdBy': user.uid,
      'createdByName': userProfile.data()?['displayName'] ?? user.email ?? '',
      'building': building.trim(),
      'laboratory': laboratory.trim(),
      'machine': machine.trim(),
      'category': category,
      'hasEvidence': hasEvidence,
      'urgency': _urgencyValue(urgency),
      'description': description.trim(),
      'status': 'pendiente',
      'technicianId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return report.id;
  }

  Future<void> updateStatus({
    required String reportId,
    required ReportStatus status,
  }) {
    _requireUser();
    return _reports.doc(reportId).update({
      'status': _statusValue(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMessage({
    required String reportId,
    required String body,
  }) async {
    final user = _requireUser();
    final userProfile = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    await _reports.doc(reportId).collection('messages').add({
      'authorId': user.uid,
      'authorName': userProfile.data()?['displayName'] ?? user.email ?? '',
      'body': body.trim(),
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchMessages(
    String reportId,
  ) {
    _requireUser();
    return _reports
        .doc(reportId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Se requiere una sesión iniciada.');
    return user;
  }

  String _urgencyValue(Urgency urgency) => switch (urgency) {
    Urgency.baja => 'baja',
    Urgency.media => 'media',
    Urgency.alta => 'alta',
  };

  String _statusValue(ReportStatus status) => switch (status) {
    ReportStatus.pendiente => 'pendiente',
    ReportStatus.enAtencion => 'enAtencion',
    ReportStatus.resuelto => 'resuelto',
  };
}
