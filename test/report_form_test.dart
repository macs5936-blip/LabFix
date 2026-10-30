import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reportes_labs_espoch/data/report_model.dart';
import 'package:reportes_labs_espoch/models/report_model.dart' as backend_models;
import 'package:reportes_labs_espoch/presentation/screens/student/report_form_screen.dart';
import 'package:reportes_labs_espoch/services/firestore_service.dart';
import 'package:reportes_labs_espoch/services/notification_service.dart';
import 'package:reportes_labs_espoch/services/storage_service.dart';

class MockStorageService extends Fake implements StorageService {
  final List<String> uploadedFiles = [];

  @override
  Future<String> uploadReportImage({
    required XFile file,
    String? customFileName,
  }) async {
    uploadedFiles.add(file.name);
    return 'https://firebasestorage.googleapis.com/test_bucket/report_images/${file.name}';
  }

  @override
  Future<String> uploadImageBytes({
    required dynamic bytes,
    required String storagePath,
    String contentType = 'image/jpeg',
  }) async {
    return 'https://firebasestorage.googleapis.com/test_bucket/$storagePath';
  }
}

class MockFirestoreService extends Fake implements FirestoreService {
  backend_models.ReportModel? lastSavedReport;

  @override
  Future<String> createReport(backend_models.ReportModel report) async {
    lastSavedReport = report;
    return report.reportId;
  }
}

class MockNotificationService extends Fake implements NotificationService {
  backend_models.ReportModel? lastNotifiedReport;

  @override
  Future<String> sendNotificationToTechnicians(backend_models.ReportModel report) async {
    lastNotifiedReport = report;
    return 'notif_123';
  }
}

void main() {
  group('CreateReportScreen / NewReportScreen submission logic', () {
    testWidgets('submits report and connects Storage, Firestore and Notifications', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockStorage = MockStorageService();
      final mockFirestore = MockFirestoreService();
      final mockNotification = MockNotificationService();

      IncidentReport? submittedIncident;

      await tester.pumpWidget(
        MaterialApp(
          home: CreateReportScreen(
            onSubmit: (report) => submittedIncident = report,
            storageService: mockStorage,
            firestoreService: mockFirestore,
            notificationService: mockNotification,
          ),
        ),
      );

      // Select Lab
      await tester.tap(find.byKey(const Key('lab-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lab. Software #1').last);
      await tester.pumpAndSettle();

      // Select Category
      await tester.tap(find.byKey(const Key('category-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hardware').last);
      await tester.pumpAndSettle();

      // Enter Equipment
      await tester.enterText(find.byKey(const Key('equipment-field')), 'PC-TEST-99');

      // Enter Description
      await tester.enterText(
        find.byKey(const Key('description-field')),
        'El monitor del equipo parpadea y huele a quemado.',
      );

      // Attach evidence
      await tester.tap(find.byKey(const Key('attach-evidence')));
      await tester.pumpAndSettle();
      expect(find.text('evidencia_seleccionada.jpg'), findsOneWidget);

      // Submit
      await tester.tap(find.byKey(const Key('submit-report')));
      await tester.pumpAndSettle();

      // Expect success dialog
      expect(find.text('¡Reporte Registrado con Éxito!'), findsOneWidget);
      expect(find.byKey(const Key('return-to-dashboard')), findsOneWidget);

      // Verify Firestore received ReportModel
      expect(mockFirestore.lastSavedReport, isNotNull);
      expect(mockFirestore.lastSavedReport!.laboratory, equals('Lab. Software #1'));
      expect(mockFirestore.lastSavedReport!.equipmentId, equals('PC-TEST-99'));
      expect(mockFirestore.lastSavedReport!.status, equals('Pendiente'));
      expect(mockFirestore.lastSavedReport!.imageUrls.isNotEmpty, isTrue);

      // Verify technician notification was dispatched
      expect(mockNotification.lastNotifiedReport, isNotNull);
      expect(mockNotification.lastNotifiedReport!.reportId, equals(mockFirestore.lastSavedReport!.reportId));

      // Verify local callback received IncidentReport
      expect(submittedIncident, isNotNull);
      expect(submittedIncident!.laboratory, equals('Lab. Software #1'));
      expect(submittedIncident!.machine, equals('PC-TEST-99'));

      // Dismiss dialog
      await tester.tap(find.byKey(const Key('return-to-dashboard')));
      await tester.pumpAndSettle();
    });
  });
}
