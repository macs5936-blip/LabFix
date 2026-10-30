import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/report_model.dart';
import '../../widgets/report_card.dart';
import 'report_detail_screen.dart';

/// Pantalla dedicada a "Mis Reportes": seguimiento y listado en tiempo real
/// de las incidencias creadas por el estudiante autenticado en Cloud Firestore.
class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({
    super.key,
    required this.reports,
    this.auth,
    this.firestore,
  });

  final List<IncidentReport> reports;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  String _filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    FirebaseAuth? currentAuth = widget.auth;
    FirebaseFirestore? currentFirestore = widget.firestore;
    try {
      if (currentAuth == null && Firebase.apps.isNotEmpty) {
        currentAuth = FirebaseAuth.instance;
      }
      if (currentFirestore == null && Firebase.apps.isNotEmpty) {
        currentFirestore = FirebaseFirestore.instance;
      }
    } catch (_) {}

    final user = currentAuth?.currentUser;
    Stream<QuerySnapshot<Map<String, dynamic>>>? reportsStream;
    if (user != null && currentFirestore != null) {
      try {
        reportsStream = currentFirestore
            .collection('reports')
            .where('userId', isEqualTo: user.uid)
            .snapshots();
      } catch (_) {
        reportsStream = null;
      }
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              user != null &&
              !snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.fieBlue),
                  SizedBox(height: 12),
                  Text(
                    'Cargando incidencias desde Firestore...',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          List<IncidentReport> sourceReports = widget.reports;

          if (snapshot.hasData && snapshot.data != null) {
            final firestoreList = snapshot.data!.docs.map((doc) {
              final data = doc.data();
              final urgencyStr = (data['urgency'] as String?)?.toLowerCase();
              final statusStr = (data['status'] as String?)?.toLowerCase();

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
                'en revision' =>
                  ReportStatus.enAtencion,
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
                  ? (doc.id.startsWith('REP-') || doc.id.startsWith('#')
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
                  (data['hasEvidence'] as bool? ?? false) || images.isNotEmpty;

              return IncidentReport(
                id: shortId,
                building: data['building'] as String? ?? 'FIE',
                laboratory: data['laboratory'] as String? ?? 'Laboratorio FIE',
                machine: data['machine'] as String? ??
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
                userId: data['userId'] as String? ??
                    data['createdBy'] as String?,
                assignedTechId: data['assignedTechId'] as String?,
                rawDocId: doc.id,
              );
            }).toList();

            firestoreList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (user != null) {
              sourceReports = firestoreList;
            } else if (firestoreList.isNotEmpty) {
              sourceReports = firestoreList;
            }
          }

          final filteredReports = _filter == 'Todos'
              ? sourceReports
              : sourceReports.where((report) {
                  if (_filter == 'En atención' || _filter == 'En revisión') {
                    return report.status == ReportStatus.enAtencion;
                  }
                  return report.statusLabel.toLowerCase() ==
                      _filter.toLowerCase();
                }).toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mis reportes',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fieBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.fieBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done_outlined,
                                size: 14,
                                color: AppColors.fieBlue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Firestore',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.fieBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Seguimiento en tiempo real de tus incidencias en laboratorios FIE.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in [
                            'Todos',
                            'Pendiente',
                            'En atención',
                            'Resuelto',
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: _filter == filter,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                                selectedColor: AppColors.fieBlue.withValues(
                                  alpha: 0.12,
                                ),
                                labelStyle: TextStyle(
                                  color: _filter == filter
                                      ? AppColors.fieBlue
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: _filter == filter
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: _filter == filter
                                      ? AppColors.fieBlue.withValues(alpha: 0.25)
                                      : AppColors.line,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${filteredReports.length} ${filteredReports.length == 1 ? 'incidencia' : 'incidencias'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filteredReports.isEmpty)
                      const _EmptyHistory()
                    else
                      for (final report in filteredReports) ...[
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 34, color: AppColors.muted),
          SizedBox(height: 10),
          Text(
            'Sin reportes en este estado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
