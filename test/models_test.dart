import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_labs_espoch/models/user_model.dart';
import 'package:reportes_labs_espoch/models/report_model.dart';
import 'package:reportes_labs_espoch/models/notification_model.dart';

void main() {
  group('UserModel Serialization', () {
    test('toMap and fromMap retain all attributes', () {
      final now = DateTime(2026, 10, 21, 10, 30);
      final user = UserModel(
        uid: 'user_123',
        nombres: 'Cristian',
        apellidos: 'Batallas',
        email: 'cristian.batallas@espoch.edu.ec',
        cedula: '0601234567',
        codigoEstudiante: '6543',
        carrera: 'Tecnologías de la Información',
        pao: 'PAO 6',
        rol: 'STUDENT',
        fotoUrl: 'https://storage.googleapis.com/avatar.jpg',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['uid'], 'user_123');
      expect(map['nombres'], 'Cristian');
      expect(map['rol'], 'STUDENT');
      expect(map['role'], 'student');
      expect(map['cedula'], '0601234567');

      final reconstructed = UserModel.fromMap(map, docId: 'user_123');
      expect(reconstructed.uid, 'user_123');
      expect(reconstructed.nombres, 'Cristian');
      expect(reconstructed.apellidos, 'Batallas');
      expect(reconstructed.rol, 'STUDENT');
      expect(reconstructed.carrera, 'Tecnologías de la Información');
      expect(reconstructed.pao, 'PAO 6');
      expect(reconstructed.fotoUrl, 'https://storage.googleapis.com/avatar.jpg');
    });

    test('supports all specified roles', () {
      for (final role in ['STUDENT', 'TECHNICIAN', 'ADMIN', 'DEANERY']) {
        final u = UserModel(
          uid: 'uid_$role',
          nombres: 'Test',
          apellidos: 'Role',
          email: 'role@espoch.edu.ec',
          rol: role,
        );
        expect(u.rol, role);
        final map = u.toMap();
        expect(map['rol'], role);
        expect(UserModel.fromMap(map).rol, role);
      }
    });
  });

  group('ReportModel Serialization', () {
    test('toMap and fromMap retain complete reporting properties', () {
      final now = DateTime(2026, 10, 21, 14, 0);
      final report = ReportModel(
        reportId: 'REP-001',
        userId: 'student_99',
        userName: 'Estudiante Politécnico',
        userEmail: 'estudiante@espoch.edu.ec',
        building: 'FIE',
        laboratory: 'Lab. Redes y Telecomunicaciones',
        equipmentId: 'ROUTER-CISCO-02',
        latitude: -1.6582,
        longitude: -78.6783,
        category: 'Conectividad / Red',
        description: 'Puerto switch dañado, no asigna DHCP.',
        urgency: 'Alta',
        status: 'Pendiente',
        imageUrls: [
          'https://storage.googleapis.com/evidence1.jpg',
          'https://storage.googleapis.com/evidence2.jpg',
        ],
        assignedTechId: 'tech_55',
        resolutionNotes: 'Se reemplazó el conector RJ-45.',
        createdAt: now,
        updatedAt: now,
      );

      final map = report.toMap();
      expect(map['reportId'], 'REP-001');
      expect(map['building'], 'FIE');
      expect(map['latitude'], -1.6582);
      expect(map['longitude'], -78.6783);
      expect(map['imageUrls'].length, 2);
      expect(map['hasEvidence'], true);

      final reconstructed = ReportModel.fromMap(map, docId: 'REP-001');
      expect(reconstructed.reportId, 'REP-001');
      expect(reconstructed.laboratory, 'Lab. Redes y Telecomunicaciones');
      expect(reconstructed.equipmentId, 'ROUTER-CISCO-02');
      expect(reconstructed.latitude, -1.6582);
      expect(reconstructed.longitude, -78.6783);
      expect(reconstructed.imageUrls.length, 2);
      expect(reconstructed.assignedTechId, 'tech_55');
      expect(reconstructed.resolutionNotes, 'Se reemplazó el conector RJ-45.');
    });
  });

  group('NotificationModel Serialization', () {
    test('toMap and fromMap work for TECHNICIAN broadcast and direct users', () {
      final notif = NotificationModel(
        notificationId: 'notif_100',
        recipientId: 'TECHNICIAN',
        title: 'Nueva incidencia en Lab. Software #1',
        body: 'PC-04 con pantalla azul.',
        reportId: 'REP-001',
        isRead: false,
      );

      final map = notif.toMap();
      expect(map['recipientId'], 'TECHNICIAN');
      expect(map['reportId'], 'REP-001');
      expect(map['isRead'], false);

      final reconstructed = NotificationModel.fromMap(map, docId: 'notif_100');
      expect(reconstructed.notificationId, 'notif_100');
      expect(reconstructed.recipientId, 'TECHNICIAN');
      expect(reconstructed.title, 'Nueva incidencia en Lab. Software #1');
      expect(reconstructed.body, 'PC-04 con pantalla azul.');
      expect(reconstructed.isRead, false);
    });
  });
}

