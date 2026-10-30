import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../config/theme/app_theme.dart';

export '../presentation/screens/student/profile_screen.dart';

/// Menú lateral (Drawer) institucional de LabFix para estudiantes de la ESPOCH.
/// 
/// Refleja dinámicamente en el Header los datos del usuario autenticado (Firestore 'users')
/// y cuenta con navegación independiente para Inicio, Mis Reportes, Mi Perfil y Ajustes.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onOpenNotifications,
    required this.onOpenProfile,
    required this.onOpenSettings,
    required this.onOpenGuide,
    required this.onOpenSupport,
    required this.onOpenDiagnostic,
    required this.onLogout,
    this.auth,
    this.firestore,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenDiagnostic;
  final VoidCallback onLogout;
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

    Stream<DocumentSnapshot<Map<String, dynamic>>>? userStream;
    if (user != null && currentFirestore != null) {
      try {
        userStream =
            currentFirestore.collection('users').doc(user.uid).snapshots();
      } catch (_) {
        userStream = null;
      }
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header con Datos Dinámicos del Usuario ──────────────
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.fieBlue, AppColors.fieBlueDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: userStream,
                builder: (context, snapshot) {
                  String displayName = 'Estudiante FIE';
                  String email = 'estudiante.fie@espoch.edu.ec';
                  String role = 'ESTUDIANTE';
                  String avatarInitial = 'E';

                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.exists) {
                    final data = snapshot.data!.data();
                    if (data != null) {
                      final nombres = (data['nombres'] as String?)?.trim();
                      final apellidos = (data['apellidos'] as String?)?.trim();
                      final docDisplayName =
                          (data['displayName'] as String?)?.trim();
                      final docEmail = (data['email'] as String?)?.trim();
                      final docRole = (data['role'] as String?)?.trim();

                      if (nombres != null && nombres.isNotEmpty) {
                        displayName = apellidos != null && apellidos.isNotEmpty
                            ? '$nombres $apellidos'
                            : nombres;
                      } else if (docDisplayName != null &&
                          docDisplayName.isNotEmpty) {
                        displayName = docDisplayName;
                      }
                      if (docEmail != null && docEmail.isNotEmpty) {
                        email = docEmail;
                      }
                      if (docRole != null && docRole.isNotEmpty) {
                        role = docRole.toUpperCase();
                      }
                    }
                  } else if (user != null) {
                    final authName = user.displayName?.trim();
                    if (authName != null && authName.isNotEmpty) {
                      displayName = authName;
                    }
                    final authEmail = user.email?.trim();
                    if (authEmail != null && authEmail.isNotEmpty) {
                      email = authEmail;
                    }
                  }

                  if (displayName.isNotEmpty &&
                      displayName.toLowerCase() != 'estudiante' &&
                      displayName.toLowerCase() != 'estudiante fie') {
                    avatarInitial = displayName[0].toUpperCase();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.gold,
                            child: Text(
                              avatarInitial,
                              style: const TextStyle(
                                color: AppColors.fieBlueDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.school_outlined,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ROL · $role',
                          style: const TextStyle(
                            color: AppColors.fieBlueDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Menú de Navegación Lateral Independiente ───────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _AppDrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notificaciones',
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenNotifications();
                    },
                  ),
                  _AppDrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Inicio',
                    selected: selectedIndex == 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab(0);
                    },
                  ),
                  _AppDrawerItem(
                    icon: Icons.assignment_outlined,
                    label: 'Mis Reportes',
                    selected: selectedIndex == 1,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab(1);
                    },
                  ),
                  _AppDrawerItem(
                    icon: Icons.person_outline,
                    label: 'Mi Perfil',
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenProfile();
                    },
                  ),
                  _AppDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Ajustes de la App',
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenSettings();
                    },
                  ),
                  const Divider(height: 16, indent: 16, endIndent: 16),
                  _AppDrawerItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Guía de Reporte de Labs',
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenGuide();
                    },
                  ),
                  _AppDrawerItem(
                    icon: Icons.support_agent_outlined,
                    label: 'Soporte Técnico FIE',
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenSupport();
                    },
                  ),
                  _AppDrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Asistente de Diagnóstico IA',
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenDiagnostic();
                    },
                  ),
                ],
              ),
            ),

            // ── Botón de Cerrar Sesión ─────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onLogout,
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
                      horizontal: 14,
                      vertical: 13,
                    ),
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

class _AppDrawerItem extends StatelessWidget {
  const _AppDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.fieBlue : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.fieBlue : null,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.fieBlue.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
