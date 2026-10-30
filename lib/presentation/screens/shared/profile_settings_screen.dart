import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../services/test_data_seeder.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    super.key,
    this.title = 'Ajustes de la App',
    this.fullName = 'Estudiante FIE',
    this.email = 'estudiante.fie@espoch.edu.ec',
    this.role = 'ESTUDIANTE',
    this.department = 'Ing. Sistemas Computacionales',
    this.centralCode = 'EST-FIE-2024',
    this.position = 'Semestre: 6.º',
    this.auth,
    this.firestore,
  });

  final String title;
  final String fullName;
  final String email;
  final String role;
  final String department;
  final String centralCode;
  final String position;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  FirebaseAuth? get _currentAuth {
    if (auth != null) return auth;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _currentFirestore {
    if (firestore != null) return firestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  Future<void> _showInformation(
    BuildContext context,
    String title,
    String description,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(description, style: const TextStyle(height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Conecta la acción para que invoque el método real de Firebase Auth:
  /// sendPasswordResetEmail(email: currentUser.email) y muestre un aviso de éxito en pantalla.
  Future<void> _handlePasswordReset(BuildContext context, String targetEmail) async {
    final effectiveEmail = targetEmail.trim().isNotEmpty
        ? targetEmail.trim()
        : (_currentAuth?.currentUser?.email?.trim() ?? '');

    if (effectiveEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.red,
          content: Text('No hay un correo electrónico asociado a esta cuenta para restablecer contraseña.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset_outlined, color: AppColors.fieBlue),
            SizedBox(width: 10),
            Text('Cambiar Contraseña'),
          ],
        ),
        content: Text(
          'Se enviará un correo con un enlace seguro a:\n\n$effectiveEmail\n\n¿Deseas solicitar el restablecimiento de tu contraseña institucional?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.fieBlue),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enviar correo'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final authInstance = _currentAuth ?? FirebaseAuth.instance;
      await authInstance.sendPasswordResetEmail(email: effectiveEmail);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Enlace enviado a $effectiveEmail! Revisa tu bandeja de entrada.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red,
          content: Text('Error al solicitar restablecimiento: $e'),
        ),
      );
    }
  }

  void _persistPreference(String key, dynamic value) {
    final user = _currentAuth?.currentUser;
    final fs = _currentFirestore;
    if (user != null && fs != null) {
      fs.collection('users').doc(user.uid).set({
        'preferences': {key: value},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('Aviso al guardar preferencia en Firestore: $e');
      });
    }
  }

  Future<void> _runTestDataSeeder(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Poblando todas las colecciones en Firebase...',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 4),
      ),
    );

    try {
      final seeder = TestDataSeeder(firestore: _currentFirestore);
      await seeder.insertTestData();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 5),
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Todas las colecciones pobladas exitosamente para la demostración!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 5),
          content: Text('Error al insertar en Firestore: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = _currentAuth?.currentUser;

    Stream<DocumentSnapshot<Map<String, dynamic>>>? userStream;
    if (user != null && _currentFirestore != null) {
      try {
        userStream = _currentFirestore!.collection('users').doc(user.uid).snapshots();
      } catch (_) {
        userStream = null;
      }
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, snapshot) {
        String activeName = fullName;
        String activeEmail = email;
        String activeRole = role;
        String activeDepartment = department;
        String activeCode = centralCode;
        String activePosition = position;

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            final nombres = (data['nombres'] as String?)?.trim();
            final apellidos = (data['apellidos'] as String?)?.trim();
            final dName = (data['displayName'] as String?)?.trim();
            final dEmail = (data['email'] as String?)?.trim();
            final dRole = (data['role'] as String?)?.trim() ?? (data['rol'] as String?)?.trim();
            final dCarrera = (data['carrera'] as String?)?.trim();
            final dCodigo = (data['codigoEstudiante'] as String?)?.trim() ?? (data['cedula'] as String?)?.trim();
            final dPao = (data['pao'] as String?)?.trim();

            if (nombres != null && nombres.isNotEmpty) {
              activeName = (apellidos != null && apellidos.isNotEmpty)
                  ? '$nombres $apellidos'
                  : nombres;
            } else if (dName != null && dName.isNotEmpty) {
              activeName = dName;
            }

            if (dEmail != null && dEmail.isNotEmpty) activeEmail = dEmail;
            if (dRole != null && dRole.isNotEmpty) activeRole = dRole.toUpperCase();
            if (dCarrera != null && dCarrera.isNotEmpty) activeDepartment = dCarrera;
            if (dCodigo != null && dCodigo.isNotEmpty) activeCode = dCodigo;
            if (dPao != null && dPao.isNotEmpty) activePosition = 'Semestre: $dPao';
          }
        } else if (user != null) {
          if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
            activeName = user.displayName!.trim();
          }
          if (user.email != null && user.email!.trim().isNotEmpty) {
            activeEmail = user.email!.trim();
          }
        }

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: AppColors.fieBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.gold,
                      child: Text(
                        _initials(activeName),
                        style: const TextStyle(
                          color: AppColors.fieBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activeEmail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              activeRole,
                              style: const TextStyle(
                                color: AppColors.fieBlueDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Información académica / laboral',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 9),
              Card(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.account_balance_outlined,
                      label: 'Carrera / Departamento',
                      value: activeDepartment,
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Código Central',
                      value: activeCode,
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _InfoRow(
                      icon: Icons.work_outline,
                      label: 'Semestre / Puesto',
                      value: activePosition,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Ajustes y preferencias',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 9),
              Card(
                child: Column(
                  children: [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppSettings.themeMode,
                      builder: (context, mode, _) => SwitchListTile(
                        key: const Key('profile-dark-mode'),
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Modo Oscuro'),
                        subtitle: const Text('Aplicar tema oscuro en toda la app'),
                        value: mode == ThemeMode.dark,
                        activeThumbColor: AppColors.fieBlue,
                        activeTrackColor: AppColors.gold,
                        onChanged: (enabled) {
                          AppSettings.themeMode.value =
                              enabled ? ThemeMode.dark : ThemeMode.light;
                          _persistPreference('darkMode', enabled);
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppSettings.pushNotifications,
                      builder: (context, enabled, _) => SwitchListTile(
                        key: const Key('profile-push-notifications'),
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Notificaciones Push'),
                        subtitle: const Text('Avisos sobre tus reportes'),
                        value: enabled,
                        activeThumbColor: AppColors.fieBlue,
                        activeTrackColor: AppColors.gold,
                        onChanged: (value) {
                          AppSettings.pushNotifications.value = value;
                          _persistPreference('pushNotifications', value);
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppSettings.maintenanceAlerts,
                      builder: (context, enabled, _) => SwitchListTile(
                        key: const Key('profile-maintenance-alerts'),
                        secondary: const Icon(Icons.build_outlined),
                        title: const Text('Alertas de Mantenimiento'),
                        subtitle: const Text('Avisos generales de laboratorios'),
                        value: enabled,
                        activeThumbColor: AppColors.fieBlue,
                        activeTrackColor: AppColors.gold,
                        onChanged: (value) {
                          AppSettings.maintenanceAlerts.value = value;
                          _persistPreference('maintenanceAlerts', value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _ActionRow(
                      icon: Icons.lock_reset_outlined,
                      title: 'Cambiar Contraseña',
                      onTap: () => _handlePasswordReset(context, activeEmail),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ActionRow(
                      icon: Icons.menu_book_outlined,
                      title: 'Guía de Usuario FIE',
                      onTap: () => _showInformation(
                        context,
                        'Guía de Usuario FIE',
                        '1. Registro de Incidencias:\n'
                        'Selecciona el edificio (FIE o Ciencias Básicas), el laboratorio y el número de estación para reportar cualquier falla en hardware, software o red.\n\n'
                        '2. Evidencia Fotográfica:\n'
                        'Adjunta fotos claras con la cámara o galería; se almacenan en la nube para análisis del equipo técnico.\n\n'
                        '3. Asistente IA Gemini:\n'
                        'Usa el chat de Asistente IA para obtener diagnósticos automáticos en tiempo real antes de registrar la falla.\n\n'
                        '4. Estados del Ticket:\n'
                        '• Pendiente: Reporte registrado en espera de revisión.\n'
                        '• En revisión: Técnico asignado atendiendo el equipo.\n'
                        '• Resuelto: Incidencia solucionada con notas de cierre.',
                      ),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ActionRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Términos y Privacidad',
                      onTap: () => _showInformation(
                        context,
                        'Términos y Privacidad',
                        'Los datos de perfil y reportes están resguardados bajo las políticas institucionales de la ESPOCH y la FIE. La información proporcionada se utiliza exclusivamente para fines de soporte técnico, mantenimiento de infraestructura tecnológica y auditoría de calidad de los laboratorios.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Entorno de Demostración & Pruebas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 9),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  key: const Key('btn-insert-test-data'),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: AppColors.fieBlueDark),
                  ),
                  title: const Text(
                    'Insertar datos de prueba (Firestore)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Puebla todas las colecciones: users, labs, reports, schedules, assignments y resources.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.play_arrow, color: AppColors.fieBlue),
                  onTap: () => _runTestDataSeeder(context),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Acerca de la App',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 9),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: AppColors.fieBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LabFix FIE v1.2.0',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Facultad de Informática y Electrónica - ESPOCH',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _initials(String value) {
    final names = value.trim().split(RegExp(r'\s+'));
    if (names.isEmpty) return 'E';
    if (names.length == 1) return names.first.characters.first.toUpperCase();
    return '${names.first.characters.first}${names.last.characters.first}'
        .toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.fieBlue),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.fieBlue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
