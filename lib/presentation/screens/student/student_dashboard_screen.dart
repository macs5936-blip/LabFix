import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/report_model.dart';
import '../../../services/test_data_seeder.dart';
import '../../widgets/report_card.dart';
import 'report_detail_screen.dart';
import 'report_form_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({
    super.key,
    required this.reports,
    required this.onReportCreated,
    required this.onOpenHistory,
    this.auth,
    this.firestore,
  });

  final List<IncidentReport> reports;
  final ValueChanged<IncidentReport> onReportCreated;
  final VoidCallback onOpenHistory;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  Future<void> _openForm(BuildContext context, {String? category}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewReportScreen(
          onSubmit: onReportCreated,
          initialCategory: category,
          onOpenHistory: onOpenHistory,
          auth: auth,
          firestore: firestore,
        ),
      ),
    );
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
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
      final seeder = TestDataSeeder(firestore: firestore);
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
        userStream = currentFirestore
            .collection('users')
            .doc(user.uid)
            .snapshots();
      } catch (_) {
        userStream = null;
      }
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userStream,
              builder: (context, snapshot) {
                String greetingName = 'estudiante';
                String avatarInitial = 'A';

                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.exists) {
                  final data = snapshot.data!.data();
                  if (data != null) {
                    final nombres = (data['nombres'] as String?)?.trim();
                    final apellidos = (data['apellidos'] as String?)?.trim();
                    final docDisplayName = (data['displayName'] as String?)
                        ?.trim();

                    if (nombres != null && nombres.isNotEmpty) {
                      greetingName = apellidos != null && apellidos.isNotEmpty
                          ? '$nombres $apellidos'
                          : nombres;
                    } else if (docDisplayName != null &&
                        docDisplayName.isNotEmpty) {
                      greetingName = docDisplayName;
                    }
                  }
                } else {
                  final fallbackName = user?.displayName?.trim();
                  if (fallbackName != null && fallbackName.isNotEmpty) {
                    greetingName = fallbackName;
                  }
                }

                if (greetingName.isNotEmpty &&
                    greetingName.toLowerCase() != 'estudiante') {
                  avatarInitial = greetingName[0].toUpperCase();
                }

                return Container(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.fieBlue,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESPOCH · LABS',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Portal estudiantil',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            child: Text(
                              avatarInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Hola, $greetingName',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '¿Qué ocurre en\ntu laboratorio?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openForm(context),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Nuevo reporte'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.fieBlueDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Insertar datos de prueba en Firebase',
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                key: const Key('btn-dashboard-seed-data'),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _runTestDataSeeder(context),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: AppColors.gold,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            sliver: SliverList.list(
              children: [
                // ── Botón banner de inserción rápida para la demo ──────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storage_outlined,
                        color: AppColors.fieBlueDark,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Datos de Demostración (Firestore)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.fieBlueDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Puebla todas las colecciones: users, labs, reports, schedules, etc.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        key: const Key('btn-banner-seed-data'),
                        onPressed: () => _runTestDataSeeder(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.fieBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Insertar'),
                      ),
                    ],
                  ),
                ),

                // ── Estado General del Servicio FIE ─────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Laboratorios FIE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.fieBlueDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'OPERATIVO',
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Todos los laboratorios y redes disponibles · Soporte activo',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Accesos Rápidos a Reportar Incidencia ───────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reporte rápido por categoría',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(
                      Icons.bolt_outlined,
                      size: 18,
                      color: AppColors.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Atajos directos para problemas comunes en laboratorios.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickActionChip(
                        icon: Icons.computer_outlined,
                        label: 'Hardware / PC',
                        onTap: () => _openForm(context, category: 'Hardware'),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionChip(
                        icon: Icons.wifi_outlined,
                        label: 'Red / Conectividad',
                        onTap: () =>
                            _openForm(context, category: 'Conectividad / Red'),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionChip(
                        icon: Icons.code_outlined,
                        label: 'Software / SO',
                        onTap: () => _openForm(
                          context,
                          category: 'Software / Sistema Operativo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reportes recientes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: onOpenHistory,
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: (user != null && currentFirestore != null)
                      ? currentFirestore
                            .collection('reports')
                            .where('userId', isEqualTo: user.uid)
                            .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    List<IncidentReport> recentReports;

                    if (snapshot.hasData && snapshot.data != null) {
                      final docs = snapshot.data!.docs;
                      final mapped = docs.map((doc) {
                        final data = doc.data();
                        final urgencyStr = (data['urgency'] as String?)
                            ?.toLowerCase();
                        final statusStr = (data['status'] as String?)
                            ?.toLowerCase();

                        final urgency = switch (urgencyStr) {
                          'alta' => Urgency.alta,
                          'baja' => Urgency.baja,
                          _ => Urgency.media,
                        };

                        final status = switch (statusStr) {
                          'en_atencion' ||
                          'enatencion' ||
                          'en atencion' ||
                          'en revisión' ||
                          'en revision' => ReportStatus.enAtencion,
                          'resuelto' => ReportStatus.resuelto,
                          _ => ReportStatus.pendiente,
                        };

                        DateTime createdAt = DateTime.now();
                        final ts = data['createdAt'];
                        if (ts is Timestamp) {
                          createdAt = ts.toDate();
                        } else if (ts is DateTime) {
                          createdAt = ts;
                        }

                        final shortId = doc.id.length > 8
                            ? (doc.id.startsWith('REP-') ||
                                      doc.id.startsWith('#')
                                  ? doc.id
                                  : '#${doc.id.substring(0, 8).toUpperCase()}')
                            : (doc.id.startsWith('#') ? doc.id : '#${doc.id}');

                        List<String> parseImages(dynamic list) {
                          if (list is List) {
                            return list.map((e) => e.toString()).toList();
                          }
                          return [];
                        }

                        final images = parseImages(data['imageUrls']);
                        final hasEv =
                            (data['hasEvidence'] as bool? ?? false) ||
                            images.isNotEmpty;

                        return IncidentReport(
                          id: shortId,
                          building: data['building'] as String? ?? 'FIE',
                          laboratory:
                              data['laboratory'] as String? ??
                              'Laboratorio FIE',
                          machine:
                              data['machine'] as String? ??
                              data['equipmentId'] as String? ??
                              'S/N',
                          category: data['category'] as String?,
                          hasEvidence: hasEv,
                          urgency: urgency,
                          description: data['description'] as String? ?? '',
                          createdAt: createdAt,
                          status: status,
                          imageUrls: images,
                          resolutionNotes: data['resolutionNotes'] as String?,
                          userId:
                              data['userId'] as String? ??
                              data['createdBy'] as String?,
                          assignedTechId: data['assignedTechId'] as String?,
                          rawDocId: doc.id,
                        );
                      }).toList();

                      mapped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      recentReports = mapped;
                    } else if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        user != null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.fieBlue,
                          ),
                        ),
                      );
                    } else {
                      // Fallback seguro para entorno offline o widget tests
                      recentReports = reports;
                    }

                    if (recentReports.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).cardTheme.color ?? Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.fieBlue.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                color: AppColors.muted,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Aún no has registrado incidencias',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.fieBlueDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Cuando reportes una falla en un equipo o red aparecerá aquí en tiempo real.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.tonalIcon(
                              onPressed: () => _openForm(context),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Crear reporte'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.fieBlue.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: AppColors.fieBlue,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final report in recentReports.take(2)) ...[
                          ReportCard(
                            report: report,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReportDetailScreen(
                                  report: report,
                                  auth: currentAuth,
                                  firestore: currentFirestore,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.fieBlue),
      label: Text(label),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.fieBlueDark,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }
}
