import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../shared/profile_settings_screen.dart';

/// Pantalla de perfil que muestra en tiempo real todos los datos
/// almacenados en Cloud Firestore para el usuario activo de ESPOCH / FIE.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.auth,
    this.firestore,
  });

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  Widget build(BuildContext context) {
    FirebaseAuth? currentAuth = auth;
    FirebaseFirestore? currentFirestore = firestore;
    try {
      if (currentAuth == null && Firebase.apps.isNotEmpty) {
        currentAuth = FirebaseAuth.instance;
      }
      if (currentFirestore == null && Firebase.apps.isNotEmpty) {
        currentFirestore = FirebaseFirestore.instance;
      }
    } catch (_) {}

    User? user;
    try {
      user = currentAuth?.currentUser;
    } catch (_) {
      user = null;
    }

    Stream<DocumentSnapshot<Map<String, dynamic>>>? stream;
    if (user != null && currentFirestore != null) {
      try {
        stream = currentFirestore.collection('users').doc(user.uid).snapshots();
      } catch (_) {
        stream = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustes de la App',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileSettingsScreen(
                    fullName: 'Estudiante FIE',
                    email: 'estudiante.fie@espoch.edu.ec',
                    role: 'ESTUDIANTE',
                    department: 'Ing. Sistemas Computacionales',
                    centralCode: 'EST-FIE-2024',
                    position: 'Semestre: 6.º',
                    auth: currentAuth,
                    firestore: currentFirestore,
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.school_outlined, color: AppColors.gold),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.fieBlue),
            );
          }

          final data = (snapshot.hasData && snapshot.data != null && snapshot.data!.exists)
              ? snapshot.data!.data()
              : null;

          final authDisplayName = user?.displayName?.trim() ?? '';
          final authEmail = user?.email?.trim() ?? '';

          // Extracción de campos con fallbacks ordenados
          String nombres = (data?['nombres'] as String?)?.trim() ?? '';
          String apellidos = (data?['apellidos'] as String?)?.trim() ?? '';
          final email = (data?['email'] as String?)?.trim().isNotEmpty == true
              ? (data!['email'] as String).trim()
              : (authEmail.isNotEmpty ? authEmail : 'estudiante.fie@espoch.edu.ec');
          final telefono = (data?['telefono'] as String?)?.trim().isNotEmpty == true
              ? (data!['telefono'] as String).trim()
              : 'No registrado';
          final carrera = (data?['carrera'] as String?)?.trim().isNotEmpty == true
              ? (data!['carrera'] as String).trim()
              : 'Tecnologías de la Información';
          final pao = (data?['pao'] as String?)?.trim().isNotEmpty == true
              ? (data!['pao'] as String).trim()
              : 'PAO 1';
          final role = ((data?['role'] as String?)?.trim().isNotEmpty == true
                  ? (data!['role'] as String).trim()
                  : 'ESTUDIANTE')
              .toUpperCase();

          if (nombres.isEmpty && apellidos.isEmpty) {
            if (authDisplayName.isNotEmpty) {
              final parts = authDisplayName.split(' ');
              nombres = parts.first;
              apellidos = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            } else {
              nombres = 'Estudiante';
              apellidos = 'FIE';
            }
          }

          final fullName = '$nombres $apellidos'.trim();
          final initials = _getInitials(nombres, apellidos);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              // ── Header Card Institucional ESPOCH ───────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.fieBlue, AppColors.fieBlueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fieBlueDark.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.gold,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.fieBlueDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'ROL · $role',
                                      style: const TextStyle(
                                        color: AppColors.fieBlueDark,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sync,
                                          size: 11,
                                          color: Colors.white70,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'En vivo',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Sección 1: Información Personal ─────────────────────────
              _SectionTitle(
                title: 'Información Personal',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _ProfileItemTile(
                      icon: Icons.badge_outlined,
                      label: 'Nombres',
                      value: nombres.isNotEmpty ? nombres : 'No registrado',
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ProfileItemTile(
                      icon: Icons.assignment_ind_outlined,
                      label: 'Apellidos',
                      value: apellidos.isNotEmpty ? apellidos : 'No registrado',
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ProfileItemTile(
                      icon: Icons.email_outlined,
                      label: 'Correo Electrónico',
                      value: email,
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ProfileItemTile(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: telefono,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Sección 2: Información Académica ─────────────────────────
              _SectionTitle(
                title: 'Información Académica (FIE - ESPOCH)',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _ProfileItemTile(
                      icon: Icons.account_balance_outlined,
                      label: 'Carrera',
                      value: carrera,
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ProfileItemTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'PAO / Semestre',
                      value: pao,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Pie institucional ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.fieBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.fieBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      color: AppColors.fieBlue,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Datos sincronizados en tiempo real con Cloud Firestore.',
                        style: TextStyle(
                          color: AppColors.fieBlueDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _getInitials(String nombres, String apellidos) {
    final first = nombres.trim().isNotEmpty ? nombres.trim()[0].toUpperCase() : 'E';
    final second = apellidos.trim().isNotEmpty ? apellidos.trim()[0].toUpperCase() : 'F';
    return '$first$second';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.fieBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.fieBlueDark,
              ),
        ),
      ],
    );
  }
}

class _ProfileItemTile extends StatelessWidget {
  const _ProfileItemTile({
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
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.fieBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.fieBlue, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
