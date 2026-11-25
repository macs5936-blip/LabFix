import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../data/lab_model.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

/// Servicio centralizado para operaciones en Cloud Firestore en LabFix (ESPOCH)
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ??
      (Firebase.apps.isNotEmpty
          ? FirebaseFirestore.instance
          : throw StateError('Firebase has not been initialized'));

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection('reports');

  /// Guarda o actualiza la información del usuario al autenticarse o registrarse
  Future<void> saveUserData(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Obtiene los datos del usuario por UID
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, docId: doc.id);
  }

  /// Stream en tiempo real de los datos del usuario logueado
  Stream<UserModel?> streamUserData(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, docId: doc.id);
    });
  }

  /// Guarda una nueva incidencia con geolocalización y evidencias en la colección 'reports'
  Future<String> createReport(ReportModel report) async {
    final docRef = report.reportId.isNotEmpty
        ? _reportsRef.doc(report.reportId)
        : _reportsRef.doc();

    final finalReport = report.copyWith(reportId: docRef.id);
    await docRef.set(finalReport.toMap());
    return docRef.id;
  }

  /// Retorna un Stream con los reportes creados por el estudiante logueado
  Stream<List<ReportModel>> getUserReports(String uid) {
    return _reportsRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        return ReportModel.fromMap(doc.data(), docId: doc.id);
      }).toList();

      // Ordenar por fecha descendente
      reports.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return reports;
    });
  }

  /// Retorna un Stream con todos los reportes para técnicos, administradores y decanato
  Stream<List<ReportModel>> getAllReports() {
    return _reportsRef.snapshots().map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        return ReportModel.fromMap(doc.data(), docId: doc.id);
      }).toList();

      // Ordenar por fecha descendente
      reports.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return reports;
    });
  }

  /// Actualiza el estado, técnico asignado y notas de solución de una incidencia
  Future<void> updateReportStatus(
    String reportId,
    String status, {
    String? techId,
    String? notes,
    String? urgency,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (techId != null) {
      updateData['assignedTechId'] = techId;
    }

    if (notes != null) {
      updateData['resolutionNotes'] = notes;
    }

    if (urgency != null) {
      updateData['urgency'] = urgency;
    }

    await _reportsRef.doc(reportId).update(updateData);
  }

  /// Guarda un nuevo mensaje en la subcolección 'reports/{reportId}/messages'
  /// con los campos obligatorios: senderId, messageText, y createdAt.
  Future<String> sendReportMessage({
    required String reportId,
    required String senderId,
    required String messageText,
    String? author,
    bool isTechnician = false,
  }) async {
    final cleanId = reportId.startsWith('#') ? reportId.substring(1) : reportId;
    final docRef = await _reportsRef.doc(cleanId).collection('messages').add({
      'senderId': senderId,
      'messageText': messageText,
      'createdAt': FieldValue.serverTimestamp(),
      'author': author ?? (isTechnician ? 'Técnico de Laboratorio' : 'Estudiante FIE'),
      'isTechnician': isTechnician,
      'body': messageText,
      'sentAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Retorna un Stream con los mensajes en tiempo real de la subcolección 'reports/{reportId}/messages'
  Stream<List<Map<String, dynamic>>> getReportMessages(String reportId) {
    final cleanId = reportId.startsWith('#') ? reportId.substring(1) : reportId;
    return _reportsRef
        .doc(cleanId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Retorna un Stream de reportes filtrado por los laboratorios asignados al técnico.
  /// Si [assignedLabs] está vacío, retorna todos los reportes (fallback para admins).
  /// Firestore limita 'whereIn' a 10 elementos — suficiente para el contexto ESPOCH.
  Stream<List<ReportModel>> getTechnicianReports(List<String> assignedLabs) {
    if (assignedLabs.isEmpty) return getAllReports();

    final labs =
        assignedLabs.length > 10 ? assignedLabs.sublist(0, 10) : assignedLabs;

    return _reportsRef
        .where('laboratory', whereIn: labs)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        return ReportModel.fromMap(doc.data(), docId: doc.id);
      }).toList();

      // Ordenar por fecha descendente
      reports.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return reports;
    });
  }

  /// Asigna o actualiza la lista de laboratorios de un técnico en Firestore.
  Future<void> assignLabsToTechnician(String uid, List<String> labs) async {
    await _usersRef.doc(uid).update({'assignedLabs': labs});
  }

  /// Retorna un Stream en tiempo real de todos los usuarios registrados en Firestore.
  Stream<List<UserModel>> streamAllUsers() {
    return _usersRef.snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        final user = UserModel.fromMap(data, docId: doc.id);

        // Auto-reparación en segundo plano para documentos creados antes de soportar nombres y apellidos
        final hasNombres =
            (data['nombres'] as String?)?.trim().isNotEmpty ?? false;
        if (!hasNombres && user.nombres.isNotEmpty) {
          _usersRef.doc(doc.id).update({
            'nombres': user.nombres,
            'apellidos': user.apellidos,
          }).catchError((_) {});
        }

        return user;
      }).toList();

      users.sort((a, b) {
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });
      return users;
    });
  }

  /// Actualiza el rol de un usuario en Firestore ('student', 'technician', 'admin').
  Future<void> updateUserRole(String uid, String newRole) async {
    final clean = newRole.trim().toLowerCase();
    final role = switch (clean) {
      'admin' || 'administrador' || 'deanery' || 'decanato' => 'admin',
      'technician' || 'tecnico' || 'técnico' || 'tech' => 'technician',
      _ => 'student',
    };
    final rol = switch (role) {
      'admin' => 'ADMIN',
      'technician' => 'TECHNICIAN',
      _ => 'STUDENT',
    };

    await _usersRef.doc(uid).update({
      'rol': rol,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Vacía todos los documentos de las colecciones creadas (excepto la colección 'users').
  /// Retorna un resumen con la cantidad de documentos eliminados por colección.
  Future<Map<String, int>> clearAllCollectionsExceptUsers() async {
    final deletedCounts = <String, int>{};
    const collectionsToClear = [
      'reports',
      'laboratories',
      'labs',
      'notifications',
      'schedules',
      'assignments',
      'resources',
      'audit_logs',
    ];

    for (final col in collectionsToClear) {
      try {
        final snapshot = await _firestore.collection(col).get();
        var count = 0;
        for (final doc in snapshot.docs) {
          if (col == 'reports') {
            try {
              final messages = await doc.reference.collection('messages').get();
              for (final msg in messages.docs) {
                await msg.reference.delete();
              }
            } catch (_) {}
          }
          await doc.reference.delete();
          count++;
        }
        deletedCounts[col] = count;
      } catch (e) {
        deletedCounts[col] = 0;
      }
    }
    return deletedCounts;
  }

  /// Guarda o actualiza un laboratorio en Firestore
  Future<void> saveLaboratory(LabRecord lab) async {
    final data = {
      'id': lab.id,
      'name': lab.name,
      'location': lab.location,
      'capacity': lab.capacity,
      'technicianName': lab.technician,
      'technician': lab.technician,
      'availability': lab.availability.label,
      'notes': lab.notes,
      'latitude': lab.latitude,
      'longitude': lab.longitude,
      'active': lab.availability != LabAvailability.inactivo,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('laboratories').doc(lab.id).set(data, SetOptions(merge: true));
    await _firestore.collection('labs').doc(lab.id).set(data, SetOptions(merge: true));
  }

  /// Elimina un laboratorio en Firestore tanto en 'laboratories' como en 'labs'
  Future<void> deleteLaboratory(String labId, [String? labName]) async {
    try {
      await _firestore.collection('laboratories').doc(labId).delete();
    } catch (_) {}
    try {
      await _firestore.collection('labs').doc(labId).delete();
    } catch (_) {}

    if (labName != null && labName.isNotEmpty) {
      try {
        final query1 = await _firestore.collection('laboratories').where('name', isEqualTo: labName).get();
        for (final doc in query1.docs) {
          await doc.reference.delete();
        }
        final query2 = await _firestore.collection('labs').where('name', isEqualTo: labName).get();
        for (final doc in query2.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }
  }

  /// Retorna un Stream con los laboratorios guardados en Firestore
  Stream<List<LabRecord>> streamLaboratories() {
    return _firestore.collection('laboratories').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return const <LabRecord>[];
      return snapshot.docs.map((doc) {
        final d = doc.data();
        final rawAvail = (d['availability'] as String?)?.toLowerCase() ?? 'activo';
        final avail = switch (rawAvail) {
          'en mantenimiento' || 'mantenimiento' => LabAvailability.mantenimiento,
          'fuera de servicio' || 'inactivo' => LabAvailability.inactivo,
          _ => LabAvailability.activo,
        };
        return LabRecord(
          id: doc.id,
          name: d['name'] as String? ?? 'Laboratorio',
          location: d['location'] as String? ?? '',
          capacity: d['capacity']?.toString() ?? '',
          technician: d['technicianName'] as String? ?? d['technician'] as String? ?? '',
          availability: avail,
          notes: d['notes'] as String? ?? '',
          latitude: (d['latitude'] as num?)?.toDouble(),
          longitude: (d['longitude'] as num?)?.toDouble(),
        );
      }).toList();
    });
  }
}
