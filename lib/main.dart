import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/firebase_config.dart';
import 'config/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'models/report_model.dart';
import 'models/user_model.dart';
import 'data/lab_model.dart';
import 'data/report_model.dart';
import 'presentation/screens/admin/admin_home_screen.dart';
import 'presentation/screens/student/report_detail_screen.dart';
import 'presentation/screens/shared/notifications_screen.dart';
import 'presentation/screens/shared/profile_settings_screen.dart';
import 'presentation/screens/student/student_shell.dart';
import 'presentation/screens/auth/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const ReportesLabsApp());
}

class ReportesLabsApp extends StatelessWidget {
  const ReportesLabsApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, themeMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Soporte de Laboratorios FIE',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        // AuthGate handles automatic session persistence.
        // The `home` override is kept for widget-test injection.
        home: home ?? const AuthGate(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate – Persistencia de sesión con Firebase Auth
// ─────────────────────────────────────────────────────────────────────────────

/// Widget raíz que detecta si hay una sesión activa en Firebase y redirige
/// automáticamente al portal correspondiente (estudiante / técnico / admin).
///
/// Mientras carga el estado inicial muestra un splash institucional.
/// Si el stream emite [null] (cierre de sesión), regresa a [LoginScreen].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService =
      widget.authService ?? AuthService();

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty && widget.authService == null) {
      return LoginScreen(authService: _authService);
    }
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // ── 1. Esperando el primer evento del stream ────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = snapshot.data;

        // ── 2. Sin sesión activa → pantalla de login ───────────────────────
        if (user == null) {
          return LoginScreen(authService: _authService);
        }

        // ── 3. Sesión activa → resolver rol y mostrar la pantalla correcta ─
        return _RoleRouter(
          user: user,
          authService: _authService,
        );
      },
    );
  }
}

/// Resuelve el rol del usuario activo desde Firestore y navega al portal
/// adecuado sin exponer la pantalla de login.
class _RoleRouter extends StatefulWidget {
  const _RoleRouter({required this.user, required this.authService});

  final User user;
  final AuthService authService;

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  String? _role;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    try {
      final role = await widget.authService.getCurrentUserRole();
      if (mounted) setState(() { _role = role; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onLogout(BuildContext ctx) {
    unawaited(_doSignOut(ctx));
  }

  Future<void> _doSignOut(BuildContext ctx) async {
    try {
      await widget.authService.signOut();
    } catch (_) {
      // FirebaseAuth.signOut() is best-effort; stream will emit null anyway.
    }
    // AuthGate's StreamBuilder will react to the null event automatically,
    // but we still clear the navigation stack here to be explicit.
    if (!ctx.mounted) return;
    Navigator.of(ctx).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();

    if (_error != null) {
      // Role resolution failed – sign out and return to login.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onLogout(context);
      });
      return const _SplashScreen();
    }

    return switch (_role) {
      'technician' => TechnicianHomeScreen(onLogout: _onLogout),
      'admin'      => AdminHomeScreen(onLogout: _onLogout),
      _            => StudentHomeScreen(onLogout: _onLogout),
    };
  }
}

/// Pantalla de espera institucional mientras Firebase resuelve el estado de auth.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fieBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: AppColors.fieBlue,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'LabFix · ESPOCH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Verificando sesión...',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSigningIn = false;
  bool _firebaseAuthenticated = false;
  String? _authError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterStudent() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StudentHomeScreen(onLogout: _returnToLogin),
      ),
    );
  }

  void _enterTechnician() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TechnicianHomeScreen(onLogout: _returnToLogin),
      ),
    );
  }

  void _enterAdmin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AdminHomeScreen(onLogout: _returnToLogin),
      ),
    );
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _authError = 'Ingresa tu correo y contraseña.');
      return;
    }
    await _authenticate(
      () => _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _signInWithMicrosoft() =>
      _authenticate(_authService.signInWithMicrosoft);

  Future<void> _signInWithGoogle() =>
      _authenticate(_authService.signInWithGoogle);

  Future<void> _authenticate(
    Future<UserCredential?> Function() authenticate,
  ) async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _authError = null;
    });

    try {
      final credential = await authenticate();
      if (credential == null) return;

      _firebaseAuthenticated = true;
      final role = await _authService.getCurrentUserRole();
      if (!mounted) return;

      final normalizedRole = AuthService.normalizeRole(role);
      switch (normalizedRole) {
        case 'student':
        case 'estudiante':
          _enterStudent();
        case 'technician':
        case 'tecnico':
          _enterTechnician();
        case 'admin':
        case 'deanery':
        case 'decanato':
          _enterAdmin();
        default:
          await _authService.signOut();
          _firebaseAuthenticated = false;
          setState(() => _authError = 'Tu cuenta no tiene un rol válido ($role).');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _authError = _authErrorMessage(error));
    } on StateError catch (error) {
      if (mounted) setState(() => _authError = error.message.toString());
    } on Exception catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (mounted) setState(() => _authError = message);
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(
          () => _authError = message.isNotEmpty
              ? message
              : 'No se pudo iniciar sesión. Verifica la configuración e inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) => switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Correo o contraseña incorrectos.',
    'invalid-email' => 'El correo no tiene un formato válido.',
    'user-disabled' => 'Esta cuenta está deshabilitada.',
    'too-many-requests' =>
      'Demasiados intentos. Espera un momento y vuelve a intentarlo.',
    'network-request-failed' => 'No hay conexión. Revisa tu acceso a internet.',
    _ => error.message ?? 'No se pudo iniciar sesión.',
  };

  void _returnToLogin(BuildContext portalContext) {
    unawaited(_signOutAndReturn(portalContext));
  }

  Future<void> _signOutAndReturn(BuildContext portalContext) async {
    if (_firebaseAuthenticated) {
      try {
        await _authService.signOut();
      } catch (_) {
        // Return to login even if the provider sign-out fails.
      }
      _firebaseAuthenticated = false;
    }
    if (!portalContext.mounted) return;
    Navigator.of(portalContext).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.fieBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: AppColors.fieBlue,
                                size: 29,
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ESPOCH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Facultad de Informática y Electrónica',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 27),
                        const Text(
                          'Soporte de laboratorios',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Accede al portal de tu rol en la FIE.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Iniciar sesión',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Usa tu correo institucional para continuar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo Institucional',
                      hintText: 'nombre@espoch.edu.ec',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onSubmitted: (_) => _signInWithEmail(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 21),
                  FilledButton.icon(
                    key: const Key('login-email'),
                    onPressed: _isSigningIn ? null : _signInWithEmail,
                    icon: _isSigningIn
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.alternate_email),
                    label: const Text('Ingresar con correo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.fieBlue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('login-espoch'),
                    onPressed: _isSigningIn ? null : _signInWithMicrosoft,
                    icon: const Icon(Icons.account_balance_outlined, size: 22),
                    label: const Text('Iniciar sesión con cuenta ESPOCH'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.fieBlue,
                      side: const BorderSide(color: AppColors.fieBlue),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('login-google'),
                    onPressed: _isSigningIn ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Iniciar sesión con Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black26),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (_authError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _authError!,
                      key: const Key('login-error'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      GestureDetector(
                        key: const Key('go-to-register'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  RegisterScreen(authService: _authService),
                            ),
                          );
                        },
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            color: AppColors.fieBlue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.fieBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({
    super.key,
    required this.onLogout,
    this.auth,
    this.firestore,
  });

  final ValueChanged<BuildContext> onLogout;

  /// Optional Firebase overrides for dependency injection in widget tests.
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  String _selectedLabFilter = 'Todos';

  // Fallback demo/offline state (utilizado cuando no hay backend activo en pruebas)
  int _fallbackPendingCount = 5;
  int _fallbackInProgressCount = 3;
  int _fallbackResolvedCount = 12;

  final List<ReportModel> _fallbackReports = [
    ReportModel(
      reportId: '#LAB-2026-31',
      laboratory: 'Lab. Microprocesadores',
      equipmentId: 'PC #08',
      description:
          'El equipo no inicia sesión y la pantalla parpadea al cargar el sistema.',
      urgency: 'Alta',
      status: 'Pendiente',
      userId: 'test_student',
      userName: 'Estudiante FIE',
      userEmail: 'estudiante.fie@espoch.edu.ec',
      building: 'FIE',
      category: 'Soporte de laboratorio',
      createdAt: DateTime(2026, 10, 3, 9, 15),
    ),
    ReportModel(
      reportId: '#LAB-2026-27',
      laboratory: 'Lab. Redes y Telecomunicaciones',
      equipmentId: 'PC #14',
      description:
          'No hay conexión a internet; el puerto de red no muestra actividad.',
      urgency: 'Media',
      status: 'En revisión',
      userId: 'test_student',
      userName: 'Estudiante FIE',
      userEmail: 'estudiante.fie@espoch.edu.ec',
      building: 'FIE',
      category: 'Soporte de laboratorio',
      createdAt: DateTime(2026, 10, 2, 11, 30),
    ),
    ReportModel(
      reportId: '#LAB-2026-19',
      laboratory: 'Lab. Hardware',
      equipmentId: 'PC #03',
      description: 'El puerto USB frontal no reconoce memorias ni periféricos.',
      urgency: 'Baja',
      status: 'Pendiente',
      userId: 'test_student',
      userName: 'Estudiante FIE',
      userEmail: 'estudiante.fie@espoch.edu.ec',
      building: 'FIE',
      category: 'Soporte de laboratorio',
      createdAt: DateTime(2026, 10, 1, 14, 5),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Firebase accessors (defensive — safe in test environments without Firebase)
  // ---------------------------------------------------------------------------

  FirebaseAuth? get _auth {
    if (widget.auth != null) return widget.auth;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _firestoreInstance {
    if (widget.firestore != null) return widget.firestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  FirestoreService get _firestoreService =>
      FirestoreService(firestore: _firestoreInstance);

  // ---------------------------------------------------------------------------
  // Status cycle: Pendiente → En revisión → Resuelto
  // ---------------------------------------------------------------------------

  String _nextStatus(String current) {
    return switch (current) {
      'Pendiente' => 'En revisión',
      'En revisión' || 'En atencion' || 'En atención' => 'Resuelto',
      _ => current,
    };
  }

  String _statusActionLabel(String status) => switch (status) {
    'Pendiente' => 'Actualizar Estado',
    'En revisión' || 'En atencion' || 'En atención' => 'Resolver',
    _ => 'Incidencia Resuelta',
  };

  String _statusDisplayLabel(String status) => switch (status) {
    'Pendiente' => 'Pendiente',
    'En revisión' || 'En atencion' || 'En atención' => 'En Proceso',
    _ => 'Resuelto',
  };

  Future<void> _updateStatus(ReportModel report) async {
    final next = _nextStatus(report.status);
    if (next == report.status) return; // already resolved

    final uid = _auth?.currentUser?.uid;
    final hasBackend =
        uid != null && (_firestoreInstance != null || Firebase.apps.isNotEmpty);

    if (hasBackend) {
      try {
        await _firestoreService.updateReportStatus(
          report.reportId,
          next,
          techId: uid,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar estado: $e')),
          );
        }
      }
    } else {
      // Modo local / prueba widget sin backend
      setState(() {
        final idx =
            _fallbackReports.indexWhere((r) => r.reportId == report.reportId);
        if (idx != -1) {
          final old = _fallbackReports[idx];
          if (old.status == 'Pendiente') {
            _fallbackPendingCount--;
            _fallbackInProgressCount++;
          } else if (old.status == 'En revisión' ||
              old.status == 'En atencion' ||
              old.status == 'En atención') {
            _fallbackInProgressCount--;
            _fallbackResolvedCount++;
          }
          _fallbackReports[idx] = old.copyWith(status: next);
        }
      });
    }
  }

  Future<void> _updateUrgency(ReportModel report, String urgency) async {
    final uid = _auth?.currentUser?.uid;
    final hasBackend =
        uid != null && (_firestoreInstance != null || Firebase.apps.isNotEmpty);
    if (hasBackend) {
      try {
        await _firestoreService.updateReportStatus(
          report.reportId,
          report.status,
          urgency: urgency,
        );
      } catch (_) {}
    } else {
      setState(() {
        final idx =
            _fallbackReports.indexWhere((r) => r.reportId == report.reportId);
        if (idx != -1) {
          _fallbackReports[idx] =
              _fallbackReports[idx].copyWith(urgency: urgency);
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  Future<void> _confirmLogout(BuildContext context) async {
    Navigator.of(context).pop();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar la sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted && context.mounted) {
      widget.onLogout(context);
    }
  }

  void _openNotifications(
    BuildContext context,
    List<ReportModel> currentReports,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          reports: currentReports.map((r) => r.toIncidentReport()).toList(),
          isTechnician: true,
          auth: _auth,
          firestore: _firestoreInstance,
        ),
      ),
    );
  }

  void _openTechnicianProfile(BuildContext context, UserModel? techUser) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSettingsScreen(
          fullName: techUser?.displayName.isNotEmpty == true
              ? techUser!.displayName
              : 'Técnico de Laboratorio',
          email: techUser?.email.isNotEmpty == true
              ? techUser!.email
              : 'soporte.fie@espoch.edu.ec',
          role: 'TÉCNICO',
          department: 'Soporte Técnico · FIE',
          centralCode: techUser?.codigoEstudiante.isNotEmpty == true
              ? techUser!.codigoEstudiante
              : 'TEC-FIE-014',
          position: 'Puesto: Técnico de laboratorio',
          auth: _auth,
          firestore: _firestoreInstance,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final uid = _auth?.currentUser?.uid;
    final hasBackend =
        uid != null && (_firestoreInstance != null || Firebase.apps.isNotEmpty);

    if (!hasBackend) {
      return _buildScaffold(
        context,
        techUser: null,
        assignedLabs: const [],
        reports: _fallbackReports,
        isLiveFirestore: false,
      );
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.streamUserData(uid),
      builder: (context, userSnap) {
        final techUser = userSnap.data;
        final assignedLabs = techUser?.assignedLabs ?? const [];

        return StreamBuilder<List<ReportModel>>(
          stream: _firestoreService.getTechnicianReports(assignedLabs),
          builder: (context, reportsSnap) {
            if (reportsSnap.hasError) {
              return _buildScaffold(
                context,
                techUser: techUser,
                assignedLabs: assignedLabs,
                reports: const [],
                errorMessage: 'Error al cargar incidencias.',
                isLiveFirestore: true,
              );
            }

            final reports = reportsSnap.data ?? const [];
            return _buildScaffold(
              context,
              techUser: techUser,
              assignedLabs: assignedLabs,
              reports: reports,
              isLoading: reportsSnap.connectionState == ConnectionState.waiting,
              isLiveFirestore: true,
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    UserModel? techUser,
    required List<String> assignedLabs,
    required List<ReportModel> reports,
    bool isLoading = false,
    bool isLiveFirestore = false,
    String? errorMessage,
  }) {
    // Compute counters
    final int pendingCount = isLiveFirestore
        ? reports.where((r) => r.status == 'Pendiente').length
        : _fallbackPendingCount;
    final int inProgressCount = isLiveFirestore
        ? reports
            .where((r) =>
                r.status == 'En revisión' ||
                r.status == 'En atencion' ||
                r.status == 'En atención')
            .length
        : _fallbackInProgressCount;
    final int resolvedCount = isLiveFirestore
        ? reports.where((r) => r.status == 'Resuelto').length
        : _fallbackResolvedCount;

    // Apply lab filter
    final filtered = _selectedLabFilter == 'Todos'
        ? reports
        : reports.where((r) => r.laboratory == _selectedLabFilter).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Soporte Técnico FIE',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Abrir menú técnico',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => _openNotifications(context, reports),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      drawer: _buildDrawer(
        context,
        techUser: techUser,
        assignedLabs: assignedLabs,
        reports: reports,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                // ── Header banner ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.fieBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portal de Soporte Técnico - FIE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Resumen de incidencias y asignaciones',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Error banner ──
                if (errorMessage != null) ...[
                  Card(
                    color: AppColors.red.withValues(alpha: 0.08),
                    child: ListTile(
                      leading:
                          const Icon(Icons.error_outline, color: AppColors.red),
                      title: Text(errorMessage,
                          style: const TextStyle(color: AppColors.red)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Metric counters ──
                Text('Resumen de hoy',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        count: pendingCount,
                        label: 'Pendientes',
                        color: AppColors.red,
                        icon: Icons.notification_important_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        count: inProgressCount,
                        label: 'En Proceso',
                        color: AppColors.yellow,
                        icon: Icons.pending_actions_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        count: resolvedCount,
                        label: 'Resueltos',
                        color: AppColors.green,
                        icon: Icons.task_alt_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Incidents header + filter ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Incidentes asignados',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${filtered.length} activos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Lab filter dropdown ──
                ValueListenableBuilder<List<LabRecord>>(
                  valueListenable: LabCatalog.labs,
                  builder: (context, laboratories, _) {
                    final labNames = laboratories.map((l) => l.name).toList();
                    final options = <String>['Todos', ...labNames];
                    if (!options.contains(_selectedLabFilter)) {
                      _selectedLabFilter = 'Todos';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por laboratorio',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 3),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const Key('technician-lab-filter'),
                            value: _selectedLabFilter,
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more),
                            items: [
                              for (final option in options)
                                DropdownMenuItem(
                                  value: option,
                                  child: Text(
                                    option,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            selectedItemBuilder: (_) => [
                              for (final option in options)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    option,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedLabFilter = value);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),

                // ── Empty state ──
                if (filtered.isEmpty && !isLoading) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 56,
                            color: AppColors.muted.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          'Sin incidencias asignadas',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Los reportes de los laboratorios a tu cargo\naparecerán aquí en tiempo real.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Incident cards ──
                for (final report in filtered) ...[
                  _ReportIncidentCard(
                    report: report,
                    statusDisplayLabel: _statusDisplayLabel(report.status),
                    actionLabel: _statusActionLabel(report.status),
                    onUrgencyChanged: (urgency) =>
                        _updateUrgency(report, urgency),
                    onStatusPressed: () => _updateStatus(report),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReportDetailScreen(
                          report: report.toIncidentReport(),
                          isTechnician: true,
                          auth: _auth,
                          firestore: _firestoreInstance,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _buildDrawer(
    BuildContext context, {
    UserModel? techUser,
    required List<String> assignedLabs,
    required List<ReportModel> reports,
  }) {
    final displayName = techUser?.displayName.isNotEmpty == true
        ? techUser!.displayName
        : 'Técnico de Laboratorio';
    final email = techUser?.email.isNotEmpty == true
        ? techUser!.email
        : 'soporte.fie@espoch.edu.ec';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
              decoration: const BoxDecoration(color: AppColors.fieBlue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.gold,
                    child: Icon(
                      Icons.engineering_outlined,
                      color: AppColors.fieBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'ROL · SOPORTE TÉCNICO',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notificaciones'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openNotifications(context, reports);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Panel de incidencias'),
                    selected: true,
                    selectedTileColor:
                        AppColors.fieBlue.withValues(alpha: 0.08),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.devices_other_outlined),
                    title: const Text('Gestión de laboratorios'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _TechnicianLabManagementScreen(
                            assignedLabs: assignedLabs,
                            reports: reports,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Mi Perfil / Ajustes'),
                    onTap: () => _openTechnicianProfile(context, techUser),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: AppColors.red),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lab Management Screen (replaces _TechnicianInfoScreen for labs)
// ---------------------------------------------------------------------------

class _TechnicianLabManagementScreen extends StatelessWidget {
  const _TechnicianLabManagementScreen({
    this.assignedLabs = const [],
    this.reports = const [],
  });

  final List<String> assignedLabs;
  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    final details = assignedLabs.isNotEmpty
        ? [
            for (final lab in assignedLabs)
              '$lab · ${reports.where((r) => r.laboratory == lab && r.status != 'Resuelto').length} incidencias',
          ]
        : const [
            'Lab. Microprocesadores · 24 equipos · Operativo',
            'Lab. Redes · 20 equipos · Operativo',
            'Lab. Hardware · 18 equipos · 2 incidencias',
            'Lab. Software · 30 equipos · Operativo',
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de laboratorios')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          for (final detail in details)
            Card(
              child: ListTile(
                leading: const Icon(Icons.computer_outlined,
                    color: AppColors.fieBlue),
                title: Text(detail),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric card widget
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int count;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Incident card widget — driven by ReportModel from Firestore
// ---------------------------------------------------------------------------

class _ReportIncidentCard extends StatelessWidget {
  const _ReportIncidentCard({
    required this.report,
    required this.statusDisplayLabel,
    required this.actionLabel,
    required this.onUrgencyChanged,
    required this.onStatusPressed,
    required this.onTap,
  });

  final ReportModel report;
  final String statusDisplayLabel;
  final String actionLabel;
  final ValueChanged<String> onUrgencyChanged;
  final VoidCallback onStatusPressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isResolved = report.status == 'Resuelto';
    final isInProgress = report.status == 'En revisión' ||
        report.status == 'En atencion' ||
        report.status == 'En atención';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.fieBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.computer_outlined,
                      color: AppColors.fieBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.laboratory,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.equipmentId,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _IncidentStatusBadge(status: statusDisplayLabel),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                report.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              const Text(
                'Prioridad',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                children: [
                  for (final p in const ['Alta', 'Media', 'Baja'])
                    _UrgencyChip(
                      label: p,
                      selected: report.urgency == p,
                      onSelected: () => onUrgencyChanged(p),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isResolved ? null : onStatusPressed,
                  icon: Icon(
                    isInProgress
                        ? Icons.check_circle_outline
                        : Icons.sync,
                  ),
                  label: Text(actionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isInProgress ? AppColors.green : AppColors.fieBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Urgency chip widget
// ---------------------------------------------------------------------------

class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Alta' => AppColors.red,
      'Media' => AppColors.yellow,
      _ => AppColors.green,
    };
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.13),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      side: BorderSide(color: selected ? color : AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ---------------------------------------------------------------------------
// Incident status badge widget
// ---------------------------------------------------------------------------

class _IncidentStatusBadge extends StatelessWidget {
  const _IncidentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Pendiente' => AppColors.red,
      'En Proceso' => AppColors.yellow,
      _ => AppColors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
