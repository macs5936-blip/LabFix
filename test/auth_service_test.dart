import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_labs_espoch/main.dart';
import 'package:reportes_labs_espoch/presentation/screens/admin/admin_home_screen.dart';
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

  bool verificationEmailSent = false;

  @override
  String? get displayName => 'Usuario Prueba';

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {
    verificationEmailSent = true;
  }

  @override
  Future<void> reload() async {}
}

class FakeUserCredential extends Fake implements UserCredential {
  FakeUserCredential(this.user);

  @override
  final User? user;
}

class FakeRoleAuthService extends AuthService {
  FakeRoleAuthService({
    required this.role,
    required FirebaseAuth auth,
  }) : super(auth: auth);

  final String role;

  @override
  Future<String> getCurrentUserRole() async => role;

  @override
  Future<UserCredential?> signInWithGoogle([AuthProvider? provider]) async {
    return FakeUserCredential(FakeUser(email: 'test@espoch.edu.ec'));
  }
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  bool signedOut = false;
  AuthProvider? lastProvider;
  AuthCredential? lastCredential;
  User? mockUser;

  @override
  User? get currentUser => mockUser;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    lastProvider = provider;
    return FakeUserCredential(mockUser);
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    lastProvider = provider;
    return FakeUserCredential(mockUser);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    lastCredential = credential;
    return FakeUserCredential(mockUser);
  }
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    mockUser = FakeUser(email: email, uid: 'new-user-123');
    return FakeUserCredential(mockUser);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    mockUser ??= FakeUser(email: email, uid: 'signed-in-user');
    return FakeUserCredential(mockUser);
  }
}

void main() {
  group('AuthService', () {
    test('isValidEspochEmail validates email domains accurately', () {
      expect(AuthService.isValidEspochEmail('estudiante@espoch.edu.ec'), isTrue);
      expect(AuthService.isValidEspochEmail('DOCENTE.FIE@ESPOCH.EDU.EC'), isTrue);
      expect(AuthService.isValidEspochEmail('soporte.fie@espoch.edu.ec'), isTrue);
      expect(AuthService.isValidEspochEmail('usuario@gmail.com'), isFalse);
      expect(AuthService.isValidEspochEmail(null), isFalse);
    });

    test('signInWithGoogle signs in using GoogleAuthProvider', () async {
      final fakeAuth = FakeFirebaseAuth()
        ..mockUser = FakeUser(email: 'usuario.espoch@gmail.com');

      final authService = AuthService(auth: fakeAuth);
      final provider = GoogleAuthProvider();

      final credential = await authService.signInWithGoogle(provider);

      expect(credential, isNotNull);
      expect(fakeAuth.lastProvider, isA<GoogleAuthProvider>());
      expect(
        (fakeAuth.lastProvider as GoogleAuthProvider).providerId,
        equals('google.com'),
      );
      expect(credential!.user?.email, equals('usuario.espoch@gmail.com'));
    });

    test('signInWithMicrosoft uses OAuthProvider microsoft.com', () async {
      final fakeAuth = FakeFirebaseAuth()
        ..mockUser = FakeUser(email: 'docente@espoch.edu.ec');

      final authService = AuthService(auth: fakeAuth);

      final credential = await authService.signInWithMicrosoft();

      expect(credential, isNotNull);
      expect(fakeAuth.lastProvider, isA<OAuthProvider>());
      expect(
        (fakeAuth.lastProvider as OAuthProvider).providerId,
        equals('microsoft.com'),
      );
      expect(credential!.user?.email, equals('docente@espoch.edu.ec'));
    });

    test('signInWithMicrosoft rejects non-espoch emails and signs out',
        () async {
      final fakeAuth = FakeFirebaseAuth()
        ..mockUser = FakeUser(email: 'intruso@gmail.com');

      final authService = AuthService(auth: fakeAuth);

      await expectLater(
        () => authService.signInWithMicrosoft(),
        throwsA(
          predicate(
            (e) =>
                e is AuthException &&
                e.toString().contains(
                  'Acceso denegado: Solo cuentas institucionales (@espoch.edu.ec)',
                ),
          ),
        ),
      );

      expect(fakeAuth.signedOut, isTrue);
    });

    test('signInWithEspoch delegates to signInWithMicrosoft', () async {
      final fakeAuth = FakeFirebaseAuth()
        ..mockUser = FakeUser(email: 'estudiante@espoch.edu.ec');

      final authService = AuthService(auth: fakeAuth);

      final credential = await authService.signInWithEspoch();

      expect(credential, isNotNull);
      expect(fakeAuth.lastProvider, isA<OAuthProvider>());
      expect(credential!.user?.email, equals('estudiante@espoch.edu.ec'));
    });

    test('registerStudent creates user, sends email verification and sets display name', () async {
      final fakeAuth = FakeFirebaseAuth();
      final authService = AuthService(auth: fakeAuth);

      final credential = await authService.registerStudent(
        nombres: 'Carlos Andrés',
        apellidos: 'Pérez López',
        telefono: '0987654321',
        email: 'carlos.perez@espoch.edu.ec',
        password: 'Password123!',
        carrera: 'Software',
        pao: 'PAO 5',
      );

      expect(credential.user?.email, equals('carlos.perez@espoch.edu.ec'));
      expect(credential.user?.uid, equals('new-user-123'));
      expect((credential.user as FakeUser).verificationEmailSent, isTrue);
    });

    test('signIn throws AuthException and signs out if email is not verified', () async {
      final unverifiedUser = FakeUser(
        email: 'alumno@espoch.edu.ec',
        emailVerified: false,
      );
      final fakeAuth = FakeFirebaseAuth()..mockUser = unverifiedUser;
      final authService = AuthService(auth: fakeAuth);

      await expectLater(
        () => authService.signIn(
          email: 'alumno@espoch.edu.ec',
          password: 'Password123!',
        ),
        throwsA(
          predicate(
            (e) =>
                e is AuthException &&
                e.toString().contains('verificar tu correo'),
          ),
        ),
      );

      expect(fakeAuth.signedOut, isTrue);
    });

    test('signIn proceeds normally if email is verified', () async {
      final verifiedUser = FakeUser(
        email: 'alumno@espoch.edu.ec',
        emailVerified: true,
      );
      final fakeAuth = FakeFirebaseAuth()..mockUser = verifiedUser;
      final authService = AuthService(auth: fakeAuth);

      final credential = await authService.signIn(
        email: 'alumno@espoch.edu.ec',
        password: 'Password123!',
      );

      expect(credential.user?.email, equals('alumno@espoch.edu.ec'));
      expect(fakeAuth.signedOut, isFalse);
    });

    test('normalizeRole handles uppercase, lowercase, English, Spanish and accented roles', () {
      // Student variations
      expect(AuthService.normalizeRole('student'), equals('student'));
      expect(AuthService.normalizeRole('STUDENT'), equals('student'));
      expect(AuthService.normalizeRole('estudiante'), equals('student'));
      expect(AuthService.normalizeRole('ESTUDIANTE'), equals('student'));
      expect(AuthService.normalizeRole('  Student  '), equals('student'));

      // Technician variations
      expect(AuthService.normalizeRole('technician'), equals('technician'));
      expect(AuthService.normalizeRole('TECHNICIAN'), equals('technician'));
      expect(AuthService.normalizeRole('tecnico'), equals('technician'));
      expect(AuthService.normalizeRole('TECNICO'), equals('technician'));
      expect(AuthService.normalizeRole('técnico'), equals('technician'));
      expect(AuthService.normalizeRole('TÉCNICO'), equals('technician'));
      expect(AuthService.normalizeRole('tech'), equals('technician'));

      // Deanery and Admin variations
      expect(AuthService.normalizeRole('deanery'), equals('admin'));
      expect(AuthService.normalizeRole('DEANERY'), equals('admin'));
      expect(AuthService.normalizeRole('decanato'), equals('admin'));
      expect(AuthService.normalizeRole('DECANATO'), equals('admin'));
      expect(AuthService.normalizeRole('admin'), equals('admin'));
      expect(AuthService.normalizeRole('ADMIN'), equals('admin'));
      expect(AuthService.normalizeRole('administrador'), equals('admin'));
      expect(AuthService.normalizeRole('ADMINISTRADOR'), equals('admin'));

      // Fallback
      expect(AuthService.normalizeRole(null), equals('student'));
    });
  });

  group('Login & Register UI', () {
    testWidgets('login screen shows full form, 3 auth buttons, and register link',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ReportesLabsApp());

      // Email/password fields
      expect(find.text('Correo Institucional'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);

      // Three auth buttons present
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.text('Ingresar con correo'), findsOneWidget);
      expect(find.byKey(const Key('login-espoch')), findsOneWidget);
      expect(find.text('Iniciar sesión con cuenta ESPOCH'), findsOneWidget);
      expect(find.byKey(const Key('login-google')), findsOneWidget);
      expect(find.text('Iniciar sesión con Google'), findsOneWidget);

      // Register prompt link
      expect(find.text('¿No tienes una cuenta? '), findsOneWidget);
      expect(find.text('Regístrate aquí'), findsOneWidget);
      expect(find.byKey(const Key('go-to-register')), findsOneWidget);

      // The 3 quick access demo buttons are removed
      expect(find.text('Ingresar como Estudiante'), findsNothing);
      expect(find.text('Ingresar como Técnico'), findsNothing);
      expect(find.text('Ingresar como Administrador / Decanato'), findsNothing);
    });

    testWidgets('tapping register link navigates to RegisterScreen with all required fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ReportesLabsApp());

      await tester.ensureVisible(find.byKey(const Key('go-to-register')));
      await tester.tap(find.byKey(const Key('go-to-register')));
      await tester.pumpAndSettle();

      // Check fields in RegisterScreen
      expect(find.text('Crear cuenta'), findsWidgets);
      expect(find.byKey(const Key('register-nombres')), findsOneWidget);
      expect(find.byKey(const Key('register-apellidos')), findsOneWidget);
      expect(find.byKey(const Key('register-telefono')), findsOneWidget);
      expect(find.byKey(const Key('register-carrera')), findsOneWidget);
      expect(find.byKey(const Key('register-pao')), findsOneWidget);
      expect(find.byKey(const Key('register-email')), findsOneWidget);
      expect(find.byKey(const Key('register-password')), findsOneWidget);
      expect(find.byKey(const Key('register-confirm-password')), findsOneWidget);
      expect(find.byKey(const Key('register-submit')), findsOneWidget);
      expect(find.byKey(const Key('register-back-to-login')), findsOneWidget);

      // Back to login
      await tester.ensureVisible(find.byKey(const Key('register-back-to-login')));
      await tester.tap(find.byKey(const Key('register-back-to-login')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-email')), findsOneWidget);
    });

    testWidgets('RegisterScreen accepts cristian.batallas@espoch.edu.ec and personal emails',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ReportesLabsApp());
      await tester.ensureVisible(find.byKey(const Key('go-to-register')));
      await tester.tap(find.byKey(const Key('go-to-register')));
      await tester.pumpAndSettle();

      // Enter institutional email with multiple dots in domain
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'cristian.batallas@espoch.edu.ec',
      );
      await tester.ensureVisible(find.byKey(const Key('register-submit')));
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      // The email field should NOT show the invalid email error message
      expect(find.text('Ingresa un correo válido.'), findsNothing);
    });

    testWidgets('login routes technician role (TECHNICIAN / tecnico) to TechnicianHomeScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = FakeFirebaseAuth()
        ..mockUser = FakeUser(email: 'tecnico.fie@espoch.edu.ec');
      final authService =
          FakeRoleAuthService(role: 'TECHNICIAN', auth: fakeAuth);

      await tester.pumpWidget(ReportesLabsApp(
        home: LoginScreen(authService: authService),
      ));

      await tester.ensureVisible(find.byKey(const Key('login-google')));
      await tester.tap(find.byKey(const Key('login-google')));
      await tester.pumpAndSettle();

      expect(find.text('Portal de Soporte Técnico - FIE'), findsOneWidget);
    });

    testWidgets('login routes deanery role (DEANERY / decanato) to AdminHomeScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = FakeFirebaseAuth()
        ..mockUser = FakeUser(email: 'decanato.fie@espoch.edu.ec');
      final authService =
          FakeRoleAuthService(role: 'DEANERY', auth: fakeAuth);

      await tester.pumpWidget(ReportesLabsApp(
        home: LoginScreen(authService: authService),
      ));

      await tester.ensureVisible(find.byKey(const Key('login-google')));
      await tester.tap(find.byKey(const Key('login-google')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminHomeScreen), findsOneWidget);
      expect(find.text('Panel de Gestión y Métricas - FIE'), findsOneWidget);
    });
  });
}

