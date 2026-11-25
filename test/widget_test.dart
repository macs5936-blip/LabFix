// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reportes_labs_espoch/config/theme/app_theme.dart';
import 'package:reportes_labs_espoch/data/lab_model.dart';
import 'package:reportes_labs_espoch/data/report_model.dart';
import 'package:reportes_labs_espoch/main.dart';
import 'package:reportes_labs_espoch/presentation/screens/admin/admin_home_screen.dart';
import 'package:reportes_labs_espoch/presentation/screens/student/student_shell.dart';
import 'package:reportes_labs_espoch/services/auth_service.dart';

class FakeUser extends Fake implements User {
  FakeUser({
    required this.email,
    this.uid = 'test-uid',
    this.emailVerified = true,
  });

  @override
  final String? email;

  @override
  final String uid;

  @override
  final bool emailVerified;

  @override
  String? get displayName => 'Estudiante FIE';

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}

  @override
  Future<void> reload() async {}
}

class FakeUserCredential extends Fake implements UserCredential {
  FakeUserCredential(this.user);

  @override
  final User? user;
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? mockUser;

  @override
  User? get currentUser => mockUser;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    return FakeUserCredential(mockUser);
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    return FakeUserCredential(mockUser);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return FakeUserCredential(mockUser);
  }

  @override
  Future<void> signOut() async {}
}

void returnToLogin(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

void main() {
  test('incident report defaults to a mutable empty message list', () {
    final report = IncidentReport(
      id: 'LAB-TEST-1',
      building: 'FIE',
      laboratory: 'Lab. Redes y Telecomunicaciones',
      machine: 'PC-08',
      urgency: Urgency.media,
      description: 'Prueba de inicialización de comentarios.',
      createdAt: DateTime(2026, 10, 4),
      status: ReportStatus.pendiente,
    );

    expect(report.messages, isEmpty);
    report.messages.add(
      TicketMessage(
        author: 'Estudiante FIE',
        body: 'Comentario de prueba.',
        sentAt: DateTime(2026, 10, 4, 10),
        isTechnician: false,
      ),
    );
    expect(report.messages, hasLength(1));
  });

  testWidgets('login opens student portal and logout returns to login', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAuth = FakeFirebaseAuth()
      ..mockUser = FakeUser(email: 'estudiante.fie@espoch.edu.ec');
    final authService = AuthService(auth: fakeAuth);

    await tester.pumpWidget(ReportesLabsApp(
      home: LoginScreen(authService: authService),
    ));

    expect(find.byKey(const Key('login-google')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('login-google')));
    await tester.tap(find.byKey(const Key('login-google')));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo reporte'), findsOneWidget);
    expect(find.text('Laboratorios FIE'), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();

    expect(find.text('Estudiante FIE'), findsOneWidget);
    expect(find.text('estudiante.fie@espoch.edu.ec'), findsOneWidget);
    await tester.tap(find.text('Cerrar Sesión'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-google')), findsOneWidget);
  });

  testWidgets('technician can update incident status', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ReportesLabsApp(
      home: TechnicianHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Portal de Soporte Técnico - FIE'), findsOneWidget);
    expect(find.text('Lab. Microprocesadores'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.text('Actualizar Estado').first);
    await tester.pumpAndSettle();

    expect(find.text('En Proceso').first, findsOneWidget);
    expect(find.text('4'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Notificaciones y Avisos FIE'), findsOneWidget);
    await tester.tap(find.text('Mis Tickets'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('#LAB-2026-31'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del Reporte'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lab. Microprocesadores'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del Reporte'), findsOneWidget);
    expect(find.text('#LAB-2026-31'), findsOneWidget);
    expect(find.text('En Diagnóstico / Mantenimiento'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('ticket-message-input')),
      'Ya reinicié el equipo, el problema continúa.',
    );
    await tester.tap(find.byKey(const Key('send-ticket-message')));
    await tester.pumpAndSettle();
    expect(
      find.text('Ya reinicié el equipo, el problema continúa.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir menú técnico'));
    await tester.pumpAndSettle();
    expect(find.text('Técnico de Laboratorio'), findsOneWidget);
    await tester.tap(find.text('Mi Perfil / Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('TEC-FIE-014'), findsOneWidget);
    expect(find.text('TÉCNICO'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú técnico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Notificaciones y Avisos FIE'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú técnico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gestión de laboratorios'));
    await tester.pumpAndSettle();
    expect(
      find.text('Lab. Hardware · 18 equipos · 2 incidencias'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú técnico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar Sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-google')), findsOneWidget);
  });

  testWidgets('student can validate and submit a new FIE report', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ReportesLabsApp(
      home: StudentHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo reporte'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Nuevo Reporte'), findsOneWidget);
    final submitButton = find.byKey(const Key('submit-report'));
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Selecciona el laboratorio'), findsOneWidget);
    expect(find.text('Selecciona la categoría de falla'), findsOneWidget);

    final laboratoryDropdown = find.byKey(const Key('lab-dropdown'));
    await tester.tap(laboratoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lab. Software #1').last);
    await tester.pumpAndSettle();

    final categoryDropdown = find.byKey(const Key('category-dropdown'));
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectividad / Red').last);
    await tester.pumpAndSettle();

    final equipmentField = find.byKey(const Key('equipment-field'));
    await tester.enterText(equipmentField, 'PC-08');
    final urgencyChoice = find.byKey(const Key('urgency-alta'));
    await tester.tap(urgencyChoice);
    final descriptionField = find.byKey(const Key('description-field'));
    await tester.enterText(
      descriptionField,
      'El equipo no puede conectarse a la red del laboratorio.',
    );
    final attachEvidence = find.byKey(const Key('attach-evidence'));
    await tester.tap(attachEvidence);
    await tester.pumpAndSettle();
    expect(find.text('evidencia_seleccionada.jpg'), findsOneWidget);

    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('¡Reporte Registrado con Éxito!'), findsOneWidget);
    expect(find.textContaining('#LAB-2026-'), findsOneWidget);

    await tester.tap(find.byKey(const Key('return-to-dashboard')));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo reporte'), findsOneWidget);

    await tester.tap(find.text('Historial').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Lab. Software #1'), findsOneWidget);
    expect(find.text('Conectividad / Red'), findsOneWidget);
    expect(find.textContaining('Equipo PC-08'), findsOneWidget);
    await tester.tap(find.textContaining('#LAB-2026-').first);
    await tester.pumpAndSettle();
    expect(find.text('Evidencia fotográfica'), findsOneWidget);
    expect(
      find.text('evidencia_seleccionada.jpg · Vista previa simulada'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('ticket-message-input')),
      'Adjunto más detalles del error.',
    );
    await tester.tap(find.byKey(const Key('send-ticket-message')));
    await tester.pumpAndSettle();
    expect(find.text('Adjunto más detalles del error.'), findsOneWidget);
  });

  testWidgets('admin can review metrics, export and return to login', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ReportesLabsApp(
      home: AdminHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Notificaciones y Avisos FIE'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Panel de Gestión y Métricas - FIE'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('4.2 h'), findsOneWidget);
    expect(find.text('94.5%'), findsOneWidget);
    expect(find.text('En Mantenimiento'), findsOneWidget);

    await tester.tap(find.byKey(const Key('period-Este Semestre')));
    await tester.pumpAndSettle();
    expect(find.text('128'), findsOneWidget);
    expect(find.text('5.1 h'), findsOneWidget);
    expect(find.text('92.8%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('export-report')));
    await tester.pumpAndSettle();
    expect(find.text('Informe preparado'), findsOneWidget);
    expect(find.textContaining('Descarga simulada'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir menú de administración'));
    await tester.pumpAndSettle();
    expect(find.text('Administración / Decanato'), findsOneWidget);
    expect(find.text('decanato.fie@espoch.edu.ec'), findsOneWidget);
    await tester.tap(find.text('Mi Perfil / Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('ADM-FIE-001'), findsOneWidget);
    expect(find.text('ADMINISTRADOR'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú de administración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Notificaciones y Avisos FIE'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú de administración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar Sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-google')), findsOneWidget);
  });

  testWidgets('notifications filter, mark as read and open ticket details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ReportesLabsApp(
      home: StudentHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Notificaciones y Avisos FIE'), findsOneWidget);
    expect(find.text('Mantenimiento de red programado'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsWidgets);

    await tester.tap(find.text('Mis Tickets'));
    await tester.pumpAndSettle();
    expect(find.text('Actualización de ticket'), findsOneWidget);
    expect(find.text('Mantenimiento de red programado'), findsNothing);

    await tester.tap(find.textContaining('INC-0248'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del Reporte'), findsOneWidget);
    expect(find.text('INC-0248'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mark-all-notifications-read')));
    await tester.pumpAndSettle();
    expect(find.byType(CircleAvatar), findsNothing);

    await tester.tap(find.text('Laboratorios'));
    await tester.pumpAndSettle();
    expect(find.text('Calibración de equipos'), findsOneWidget);
    expect(find.text('Nuevo comentario en tu ticket'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Notificaciones y Avisos FIE'), findsOneWidget);
  });

  testWidgets(
    'diagnostic chatbot guides and preselects a new report category',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ReportesLabsApp(
        home: StudentHomeScreen(onLogout: returnToLogin),
      ));
      await tester.pumpAndSettle();

      // Tap the floating "Diagnóstico IA" button
      await tester.tap(find.byKey(const Key('open-diagnostic-chatbot')));
      await tester.pumpAndSettle();

      expect(
        find.text('Asistente IA (Gemini) · Conectado en vivo'),
        findsOneWidget,
      );
      expect(
        find.text('Soporte rápido'),
        findsOneWidget,
      );

      // Tap on Inicio tab to return to home
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      // Tap on bottom "Asistente IA" tab
      await tester.tap(find.text('Asistente IA'));
      await tester.pumpAndSettle();

      expect(
        find.text('Asistente IA (Gemini) · Conectado en vivo'),
        findsOneWidget,
      );
    },
  );

  testWidgets('student profile preferences change the global app theme', (
    WidgetTester tester,
  ) async {
    AppSettings.themeMode.value = ThemeMode.light;
    addTearDown(() => AppSettings.themeMode.value = ThemeMode.light);
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ReportesLabsApp(
      home: StudentHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Mi Perfil'), findsOneWidget);
    expect(find.text('Ajustes de la App'), findsOneWidget);
    await tester.tap(find.text('Ajustes de la App'));
    await tester.pumpAndSettle();

    expect(find.text('Ing. Sistemas Computacionales'), findsOneWidget);
    expect(find.text('EST-FIE-2024'), findsOneWidget);
    expect(find.text('Semestre: 6.º'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    await tester.tap(find.byKey(const Key('profile-dark-mode')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.byKey(const Key('profile-push-notifications')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('profile-push-notifications')),
          )
          .value,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('profile-maintenance-alerts')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('profile-maintenance-alerts')),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('profile-dark-mode')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('admin manages users, schedules and technician reports', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ReportesLabsApp(
      home: AdminHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    expect(find.text('Gestión de Usuarios'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('admin-user-search')),
      'TEC-FIE-014',
    );
    await tester.pumpAndSettle();
    expect(find.text('Carlos Mena'), findsOneWidget);
    expect(find.text('Ana Paredes'), findsNothing);

    await tester.tap(find.byKey(const Key('role-TEC-FIE-014')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudiante').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Rol de Carlos Mena actualizado a Estudiante'),
      findsOneWidget,
    );

    await tester.tap(find.text('Horarios'));
    await tester.pumpAndSettle();
    expect(find.text('Horarios y Disponibilidad'), findsOneWidget);
    expect(find.text('Redes I'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-schedule-block')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-time-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15:00 - 17:00').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-course-field')),
      'Laboratorio de Redes III',
    );
    await tester.enterText(
      find.byKey(const Key('schedule-teacher-field')),
      'Ing. Prueba',
    );
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();
    expect(find.text('Laboratorio de Redes III'), findsOneWidget);
    await tester.tap(find.byKey(const Key('upload-schedule')));
    await tester.pumpAndSettle();
    expect(find.text('Actualizar horario'), findsOneWidget);
    await tester.tap(find.text('Simular carga'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Técnicos'));
    await tester.pumpAndSettle();
    expect(find.text('Rendimiento de Técnicos'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    await tester.tap(find.byKey(const Key('technician-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofía Viteri').last);
    await tester.pumpAndSettle();
    expect(find.text('31'), findsOneWidget);
    expect(find.text('4.6 / 5'), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-technician-report')));
    await tester.pumpAndSettle();
    expect(find.text('Reporte individual preparado'), findsOneWidget);
  });

  testWidgets('admin registers a lab and it is selectable across portals', (
    WidgetTester tester,
  ) async {
    final originalLabs = List<LabRecord>.of(LabCatalog.labs.value);
    addTearDown(() => LabCatalog.labs.value = originalLabs);
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const newLabName = 'Lab. Inteligencia Artificial y Robótica';
    await tester.pumpWidget(const ReportesLabsApp(
      home: AdminHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horarios'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-laboratory')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial lab editor layout');

    await tester.enterText(find.byKey(const Key('lab-name-field')), newLabName);
    await tester.enterText(
      find.byKey(const Key('lab-location-field')),
      'Edificio FIE - Planta Alta, Aula 204',
    );
    await tester.enterText(
      find.byKey(const Key('lab-capacity-field')),
      '25 PCs, 2 servidores, 1 proyector',
    );
    await tester.tap(find.byKey(const Key('lab-technician-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carlos Mena').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'lab technician selector');
    await tester.enterText(
      find.byKey(const Key('lab-notes-field')),
      'Infraestructura y red listas para prácticas de IA.',
    );
    await tester.tap(find.byKey(const Key('save-laboratory')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'laboratory editor layout');
    expect(find.text('Laboratorio registrado exitosamente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('schedule-lab-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(newLabName).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'admin schedule selector');
    expect(find.text(newLabName), findsWidgets);

    final newLab = LabCatalog.labs.value.firstWhere(
      (lab) => lab.name == newLabName,
    );
    final editLabButton = find.byKey(Key('edit-lab-${newLab.id}'));
    await tester.ensureVisible(editLabButton);
    await tester.tap(editLabButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lab-availability-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('En Mantenimiento').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(
      LabCatalog.labs.value
          .firstWhere((lab) => lab.id == newLab.id)
          .availability,
      LabAvailability.mantenimiento,
    );

    await tester.tap(find.byTooltip('Abrir menú de administración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar Sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const ReportesLabsApp(
      key: ValueKey('student-portal'),
      home: StudentHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'student portal layout');
    await tester.tap(find.text('Nuevo reporte'));
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'student report form layout',
    );
    await tester.tap(find.byKey(const Key('lab-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(newLabName).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'student lab selector');
    expect(find.text(newLabName), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar Sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const ReportesLabsApp(
      key: ValueKey('tech-portal'),
      home: TechnicianHomeScreen(onLogout: returnToLogin),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'technician portal layout');
    await tester.tap(find.byKey(const Key('technician-lab-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(newLabName).last);
    await tester.pumpAndSettle();
    expect(find.text(newLabName), findsWidgets);
  });

  testWidgets(
    'student navigation separates Inicio, Mis Reportes, Mi Perfil and Ajustes with live header',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ReportesLabsApp(
        home: StudentHomeScreen(onLogout: returnToLogin),
      ));
      await tester.pumpAndSettle();

      // 1. Dashboard: saludo dinámico, estado del servicio y accesos rápidos
      expect(find.textContaining('Hola,'), findsOneWidget);
      expect(find.text('Laboratorios FIE'), findsOneWidget);
      expect(find.text('OPERATIVO'), findsOneWidget);
      expect(find.text('Reporte rápido por categoría'), findsOneWidget);

      // 2. Abrir Drawer y verificar Header dinámico
      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pumpAndSettle();

      expect(find.text('Estudiante FIE'), findsOneWidget);
      expect(find.text('estudiante.fie@espoch.edu.ec'), findsOneWidget);

      // 3. Verificar separación de ítems independientes en el Drawer
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Inicio')),
        findsOneWidget,
      );
      expect(find.text('Mis Reportes'), findsOneWidget);
      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Ajustes de la App'), findsOneWidget);

      // 4. Navegar a "Mis Reportes"
      await tester.tap(find.text('Mis Reportes'));
      await tester.pumpAndSettle();
      expect(find.text('Mis reportes'), findsOneWidget);
      expect(find.text('Firestore'), findsOneWidget);

      // 5. Abrir Drawer y volver a "Inicio"
      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Drawer), matching: find.text('Inicio')),
      );
      await tester.pumpAndSettle();
      expect(find.text('¿Qué ocurre en\ntu laboratorio?'), findsOneWidget);

      // 6. Navegar a "Mi Perfil" y validar campos en tiempo real de Firestore
      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Nombres'), findsOneWidget);
      expect(find.text('Apellidos'), findsOneWidget);
      expect(find.text('Correo Electrónico'), findsOneWidget);
      expect(find.text('Teléfono'), findsOneWidget);
      expect(find.text('Carrera'), findsOneWidget);
      expect(find.text('PAO / Semestre'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 7. Navegar a "Ajustes de la App"
      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajustes de la App'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-dark-mode')), findsOneWidget);
    },
  );
}

