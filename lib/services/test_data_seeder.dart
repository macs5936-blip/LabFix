import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

/// Script Seeder integral para poblar TODAS las colecciones requeridas en Firebase Firestore
/// para la aplicación "LabFix" de la ESPOCH (Presentaciones y Demostración)
class TestDataSeeder {
  TestDataSeeder({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Inserta datos de prueba en simultáneo para todas las colecciones del sistema
  Future<void> insertTestData() async {
    try {
      debugPrint('⏳ Iniciando carga masiva de colecciones en Firebase Firestore...');

      final batch = _firestore.batch();
      final now = DateTime.now();

      // ======================================================================
      // 1. COLECCIÓN: users (Estudiante, Técnico, Administrador, Decanato)
      // ======================================================================
      final studentUser = UserModel(
        uid: 'student_espoch_01',
        nombres: 'Cristian Joel',
        apellidos: 'Batallas Mora',
        email: 'cristian.batallas@espoch.edu.ec',
        cedula: '0604589214',
        codigoEstudiante: '7124',
        carrera: 'Tecnologías de la Información',
        pao: 'PAO 6',
        rol: 'STUDENT',
        fotoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        createdAt: now,
      );

      final technicianUser = UserModel(
        uid: 'tech_espoch_01',
        nombres: 'Carlos Alberto',
        apellidos: 'Mendoza Ramos',
        email: 'carlos.mendoza@espoch.edu.ec',
        cedula: '0602987412',
        codigoEstudiante: 'TEC-FIE-014',
        carrera: 'Soporte e Infraestructura FIE',
        pao: 'Docente / Técnico',
        rol: 'TECHNICIAN',
        fotoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        createdAt: now,
      );

      final adminUser = UserModel(
        uid: 'admin_espoch_01',
        nombres: 'Ing. Fernando Patricio',
        apellidos: 'Silva Andrade',
        email: 'fernando.silva@espoch.edu.ec',
        cedula: '0601874523',
        codigoEstudiante: 'ADM-FIE-001',
        carrera: 'Dirección de Tecnologías FIE',
        pao: 'Administrador del Sistema',
        rol: 'ADMIN',
        fotoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        createdAt: now,
      );

      final deaneryUser = UserModel(
        uid: 'deanery_espoch_01',
        nombres: 'Dr. Marco Vinicio',
        apellidos: 'Chávez Estrada',
        email: 'decanato.fie@espoch.edu.ec',
        cedula: '0601029384',
        codigoEstudiante: 'DEC-FIE-001',
        carrera: 'Decanato FIE - ESPOCH',
        pao: 'Decanato',
        rol: 'DEANERY',
        fotoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
        createdAt: now,
      );

      for (final u in [studentUser, technicianUser, adminUser, deaneryUser]) {
        final docRef = _firestore.collection('users').doc(u.uid);
        batch.set(docRef, u.toMap(), SetOptions(merge: true));
      }

      // ======================================================================
      // 2. COLECCIÓN: laboratories (FIE y Ciencias Básicas con GPS)
      // ======================================================================
      final labsData = [
        {
          'id': 'LAB-FIE-REDES',
          'name': 'Lab. Redes y Telecomunicaciones',
          'building': 'FIE',
          'location': 'Edificio FIE - Planta Alta, Aula 204',
          'capacity': 25,
          'capacityDescription': '25 PCs, 2 servidores, 1 proyector',
          'technicianId': technicianUser.uid,
          'technicianName': technicianUser.displayName,
          'availability': 'Activo',
          'latitude': -1.658350,
          'longitude': -78.678120,
          'notes': 'Rack de comunicaciones, switch capa 3 y cableado estructurado certificado.',
          'active': true,
          'createdAt': now,
        },
        {
          'id': 'LAB-FIE-SOFTWARE-1',
          'name': 'Lab. Software #1',
          'building': 'FIE',
          'location': 'Edificio FIE - Planta Baja, Aula 103',
          'capacity': 30,
          'capacityDescription': '30 PCs Intel i7, 1 proyector interactivo',
          'technicianId': technicianUser.uid,
          'technicianName': technicianUser.displayName,
          'availability': 'Activo',
          'latitude': -1.658210,
          'longitude': -78.678290,
          'notes': 'Estaciones preparadas para desarrollo web, móvil y bases de datos.',
          'active': true,
          'createdAt': now,
        },
        {
          'id': 'LAB-FIE-MICRO',
          'name': 'Lab. Microprocesadores y Hardware',
          'building': 'FIE',
          'location': 'Edificio FIE - Planta Alta, Aula 212',
          'capacity': 20,
          'capacityDescription': '20 PCs, 12 módulos FPGA y microcontroladores',
          'technicianId': technicianUser.uid,
          'technicianName': technicianUser.displayName,
          'availability': 'En Mantenimiento',
          'latitude': -1.658420,
          'longitude': -78.678050,
          'notes': 'Revisión preventiva de fuentes y módulos de práctica.',
          'active': true,
          'createdAt': now,
        },
        {
          'id': 'LAB-CB-FISICA',
          'name': 'Lab. Computación y Simulación Básica',
          'building': 'Ciencias Básicas',
          'location': 'Edificio Ciencias Básicas - Bloque B, Aula 102',
          'capacity': 28,
          'capacityDescription': '28 PCs, software Matlab y cálculo numérico',
          'technicianId': technicianUser.uid,
          'technicianName': technicianUser.displayName,
          'availability': 'Activo',
          'latitude': -1.656820,
          'longitude': -78.676450,
          'notes': 'Prácticas de álgebra lineal, cálculo y modelado para primeros semestres.',
          'active': true,
          'createdAt': now,
        },
      ];

      for (final lab in labsData) {
        final docRef = _firestore.collection('laboratories').doc(lab['id'] as String);
        batch.set(docRef, lab, SetOptions(merge: true));
        // Colección espejo 'labs' para compatibilidad retroactiva
        final mirrorRef = _firestore.collection('labs').doc(lab['id'] as String);
        batch.set(mirrorRef, lab, SetOptions(merge: true));
      }

      // ======================================================================
      // 3. COLECCIÓN: reports (Incidencias geolocalizadas campus ESPOCH)
      // ======================================================================
      final reportHardware = ReportModel(
        reportId: 'REP-ESPOCH-001',
        userId: studentUser.uid,
        userName: studentUser.displayName,
        userEmail: studentUser.email,
        building: 'FIE',
        laboratory: 'Lab. Microprocesadores y Hardware',
        equipmentId: 'PC-12',
        latitude: -1.658350,
        longitude: -78.678120,
        category: 'Hardware',
        description: 'El equipo no enciende y el ventilador de la fuente emite un sonido constante anormal.',
        urgency: 'Alta',
        status: 'Pendiente',
        imageUrls: const [
          'https://images.unsplash.com/photo-1588508065123-287b28e013da?w=600',
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      );

      final reportNetwork = ReportModel(
        reportId: 'REP-ESPOCH-002',
        userId: studentUser.uid,
        userName: studentUser.displayName,
        userEmail: studentUser.email,
        building: 'Ciencias Básicas',
        laboratory: 'Lab. Computación y Simulación Básica',
        equipmentId: 'SW-CISCO-03',
        latitude: -1.656820,
        longitude: -78.676450,
        category: 'Conectividad / Red',
        description: 'Pérdida de conectividad intermitente en las tomas RJ45 del rack B.',
        urgency: 'Media',
        status: 'Pendiente',
        imageUrls: const [
          'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=600',
        ],
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      final reportSoftware = ReportModel(
        reportId: 'REP-ESPOCH-003',
        userId: studentUser.uid,
        userName: studentUser.displayName,
        userEmail: studentUser.email,
        building: 'FIE',
        laboratory: 'Lab. Software #1',
        equipmentId: 'PC-07',
        latitude: -1.658210,
        longitude: -78.678290,
        category: 'Software / Sistema Operativo',
        description: 'Error al iniciar máquina virtual Linux: disco virtual corrupto.',
        urgency: 'Media',
        status: 'En revisión',
        assignedTechId: technicianUser.uid,
        resolutionNotes: 'Técnico asignado revisando imagen ISO.',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      );

      for (final r in [reportHardware, reportNetwork, reportSoftware]) {
        final docRef = _firestore.collection('reports').doc(r.reportId);
        batch.set(docRef, r.toMap(), SetOptions(merge: true));
      }

      // ======================================================================
      // 4. COLECCIÓN: notifications (Alertas para técnicos y estudiantes)
      // ======================================================================
      final notifTech1 = {
        'notificationId': 'NOTIF-TECH-001',
        'recipientId': 'TECHNICIAN',
        'title': '🚨 Falla crítica de Hardware en FIE',
        'body': 'Cristian Batallas reportó: PC-12 en Lab. Microprocesadores no enciende.',
        'reportId': reportHardware.reportId,
        'isRead': false,
        'createdAt': now.subtract(const Duration(minutes: 45)),
      };

      final notifTech2 = {
        'notificationId': 'NOTIF-TECH-002',
        'recipientId': technicianUser.uid,
        'title': 'Asignación de incidencia en Software #1',
        'body': 'Has sido asignado para resolver el reporte #REP-ESPOCH-003.',
        'reportId': reportSoftware.reportId,
        'isRead': false,
        'createdAt': now.subtract(const Duration(minutes: 20)),
      };

      final notifStudent = {
        'notificationId': 'NOTIF-STUDENT-001',
        'recipientId': studentUser.uid,
        'title': 'Tu reporte está en revisión',
        'body': 'El técnico Carlos Mendoza ha iniciado la atención de tu incidencia #REP-ESPOCH-003.',
        'reportId': reportSoftware.reportId,
        'isRead': false,
        'createdAt': now.subtract(const Duration(minutes: 10)),
      };

      for (final n in [notifTech1, notifTech2, notifStudent]) {
        final docRef = _firestore.collection('notifications').doc(n['notificationId'] as String);
        batch.set(docRef, n, SetOptions(merge: true));
      }

      // ======================================================================
      // 5. COLECCIÓN: schedules (Horarios de uso para control administrativo)
      // ======================================================================
      final schedulesData = [
        {
          'scheduleId': 'SCHED-001',
          'labId': 'LAB-FIE-REDES',
          'labName': 'Lab. Redes y Telecomunicaciones',
          'dayOfWeek': 'Lunes',
          'startTime': '08:00',
          'endTime': '10:00',
          'subject': 'Redes de Datos I',
          'professor': 'Ing. Carlos Mena',
          'career': 'Tecnologías de la Información',
          'semester': 'PAO 5',
          'status': 'Programada',
        },
        {
          'scheduleId': 'SCHED-002',
          'labId': 'LAB-FIE-REDES',
          'labName': 'Lab. Redes y Telecomunicaciones',
          'dayOfWeek': 'Miércoles',
          'startTime': '10:00',
          'endTime': '12:00',
          'subject': 'Telemática y Protocolos',
          'professor': 'Mgs. Ana Ruiz',
          'career': 'Telecomunicaciones',
          'semester': 'PAO 7',
          'status': 'Programada',
        },
        {
          'scheduleId': 'SCHED-003',
          'labId': 'LAB-FIE-SOFTWARE-1',
          'labName': 'Lab. Software #1',
          'dayOfWeek': 'Martes',
          'startTime': '08:00',
          'endTime': '10:00',
          'subject': 'Programación Avanzada',
          'professor': 'Mgs. Elena Paz',
          'career': 'Software',
          'semester': 'PAO 4',
          'status': 'Programada',
        },
        {
          'scheduleId': 'SCHED-004',
          'labId': 'LAB-FIE-SOFTWARE-1',
          'labName': 'Lab. Software #1',
          'dayOfWeek': 'Jueves',
          'startTime': '14:00',
          'endTime': '16:00',
          'subject': 'Sistemas Distribuidos',
          'professor': 'Ing. David León',
          'career': 'Software',
          'semester': 'PAO 6',
          'status': 'Programada',
        },
        {
          'scheduleId': 'SCHED-005',
          'labId': 'LAB-CB-FISICA',
          'labName': 'Lab. Computación y Simulación Básica',
          'dayOfWeek': 'Viernes',
          'startTime': '09:00',
          'endTime': '11:00',
          'subject': 'Métodos Numéricos y Simulación',
          'professor': 'Dr. Gonzalo Morales',
          'career': 'Ciencias Básicas FIE',
          'semester': 'PAO 2',
          'status': 'Programada',
        },
      ];

      for (final s in schedulesData) {
        final docRef = _firestore.collection('schedules').doc(s['scheduleId'] as String);
        batch.set(docRef, s, SetOptions(merge: true));
      }

      // ======================================================================
      // 6. COLECCIÓN: assignments (Técnicos asignados a zonas específicas)
      // ======================================================================
      final assignmentsData = [
        {
          'assignmentId': 'ASSIGN-FIE-ZONA-NORTE',
          'technicianId': technicianUser.uid,
          'technicianName': technicianUser.displayName,
          'technicianEmail': technicianUser.email,
          'zone': 'Zona Norte - FIE Planta Alta',
          'building': 'FIE',
          'coveredLabs': [
            'Lab. Redes y Telecomunicaciones',
            'Lab. Microprocesadores y Hardware',
          ],
          'shift': 'Matutino (07:30 - 15:30)',
          'status': 'Activo',
          'assignedAt': now,
        },
        {
          'assignmentId': 'ASSIGN-FIE-ZONA-SUR',
          'technicianId': technicianUser.uid,
          'technicianName': technicianUser.displayName,
          'technicianEmail': technicianUser.email,
          'zone': 'Zona Sur - FIE Planta Baja',
          'building': 'FIE',
          'coveredLabs': [
            'Lab. Software #1',
            'Lab. Hardware',
          ],
          'shift': 'Vespertino (12:00 - 20:00)',
          'status': 'Activo',
          'assignedAt': now,
        },
        {
          'assignmentId': 'ASSIGN-CB-CENTRAL',
          'technicianId': technicianUser.uid,
          'technicianName': technicianUser.displayName,
          'technicianEmail': technicianUser.email,
          'zone': 'Zona Central - Ciencias Básicas',
          'building': 'Ciencias Básicas',
          'coveredLabs': [
            'Lab. Computación y Simulación Básica',
          ],
          'shift': 'Rotativo',
          'status': 'Activo',
          'assignedAt': now,
        },
      ];

      for (final a in assignmentsData) {
        final docRef = _firestore.collection('assignments').doc(a['assignmentId'] as String);
        batch.set(docRef, a, SetOptions(merge: true));
      }

      // ======================================================================
      // 7. COLECCIÓN: resources (Inventario de equipos tecnológicos)
      // ======================================================================
      final resourcesData = [
        {
          'resourceId': 'RES-PC-001',
          'code': 'PC-12',
          'type': 'Computadora de Escritorio',
          'brand': 'Dell OptiPlex 7090',
          'specs': 'Intel Core i7-11700, 16GB RAM, 512GB NVMe SSD',
          'laboratory': 'Lab. Microprocesadores y Hardware',
          'building': 'FIE',
          'state': 'Con Incidencia',
          'currentReportId': reportHardware.reportId,
          'lastMaintenance': now.subtract(const Duration(days: 45)),
        },
        {
          'resourceId': 'RES-PC-002',
          'code': 'PC-07',
          'type': 'Computadora de Escritorio',
          'brand': 'HP ProDesk 600 G6',
          'specs': 'Intel Core i5-10500, 16GB RAM, 256GB SSD',
          'laboratory': 'Lab. Software #1',
          'building': 'FIE',
          'state': 'En Revisión',
          'currentReportId': reportSoftware.reportId,
          'lastMaintenance': now.subtract(const Duration(days: 20)),
        },
        {
          'resourceId': 'RES-NET-001',
          'code': 'SW-CISCO-03',
          'type': 'Switch Administrable',
          'brand': 'Cisco Catalyst 2960-X',
          'specs': '48 puertos Gigabit Ethernet PoE+, 4 enlaces SFP 1G',
          'laboratory': 'Lab. Computación y Simulación Básica',
          'building': 'Ciencias Básicas',
          'state': 'Con Incidencia',
          'currentReportId': reportNetwork.reportId,
          'lastMaintenance': now.subtract(const Duration(days: 90)),
        },
        {
          'resourceId': 'RES-ROUT-002',
          'code': 'ROUTER-CISCO-CORE',
          'type': 'Router de Borde',
          'brand': 'Cisco ISR 4331',
          'specs': '3 puertos GE WAN/LAN, 2 slots NIM, redundancia de fuente',
          'laboratory': 'Lab. Redes y Telecomunicaciones',
          'building': 'FIE',
          'state': 'Operativo',
          'currentReportId': null,
          'lastMaintenance': now.subtract(const Duration(days: 15)),
        },
        {
          'resourceId': 'RES-PROY-001',
          'code': 'PROY-EPSON-01',
          'type': 'Proyector Interactivo',
          'brand': 'Epson PowerLite L620U',
          'specs': '6000 lúmenes láser, resolución WUXGA Full HD',
          'laboratory': 'Lab. Software #1',
          'building': 'FIE',
          'state': 'Operativo',
          'currentReportId': null,
          'lastMaintenance': now.subtract(const Duration(days: 10)),
        },
      ];

      for (final res in resourcesData) {
        final docRef = _firestore.collection('resources').doc(res['resourceId'] as String);
        batch.set(docRef, res, SetOptions(merge: true));
      }

      // ======================================================================
      // 8. COLECCIÓN ADICIONAL: audit_logs (Trazabilidad y auditoría ESPOCH)
      // ======================================================================
      final auditData = [
        {
          'logId': 'LOG-INIT-001',
          'action': 'CARGA_MASIVA_DEMO',
          'performedBy': 'Sistema / Demostración ESPOCH',
          'details': 'Población inicial de colecciones: users, laboratories, reports, notifications, schedules, assignments, resources.',
          'timestamp': now,
        },
        {
          'logId': 'LOG-REP-001',
          'action': 'CREACION_REPORTE',
          'performedBy': studentUser.email,
          'details': 'Reporte #REP-ESPOCH-001 registrado con geolocalización en FIE.',
          'timestamp': now.subtract(const Duration(hours: 3)),
        },
      ];

      for (final log in auditData) {
        final docRef = _firestore.collection('audit_logs').doc(log['logId'] as String);
        batch.set(docRef, log, SetOptions(merge: true));
      }

      // Ejecutar la transacción en lote
      await batch.commit();

      debugPrint('✅ ¡Todas las colecciones pobladas exitosamente para la demostración!');
    } catch (e, stack) {
      debugPrint('❌ Error al insertar datos en colecciones: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }
}
