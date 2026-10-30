import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_theme.dart';
import '../../data/report_model.dart';
import '../../models/report_model.dart';
import '../../presentation/screens/student/report_detail_screen.dart';
import '../../presentation/widgets/report_card.dart';
import '../../services/firestore_service.dart';

/// Pantalla "Mis Reportes": Historial y seguimiento en tiempo real
/// de las incidencias creadas por el estudiante en Cloud Firestore.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({
    super.key,
    this.userId,
    this.auth,
    this.firestore,
    this.firestoreService,
    this.initialReports,
    this.showAppBar = true,
  });

  final String? userId;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final FirestoreService? firestoreService;
  final List<IncidentReport>? initialReports;
  final bool showAppBar;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedFilter = 'Todos';

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

    final service = widget.firestoreService ??
        (currentFirestore != null
            ? FirestoreService(firestore: currentFirestore)
            : FirestoreService());

    final effectiveUid = widget.userId ??
        currentAuth?.currentUser?.uid ??
        'student_espoch_01';

    final body = SafeArea(
      child: StreamBuilder<List<ReportModel>>(
        stream: service.getUserReports(effectiveUid),
        builder: (context, snapshot) {
          List<IncidentReport> reportsList = [];

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            reportsList = snapshot.data!.map((m) => _modelToIncident(m)).toList();
          } else if (snapshot.connectionState == ConnectionState.waiting &&
              widget.initialReports == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.fieBlue),
                  SizedBox(height: 14),
                  Text(
                    'Cargando reportes desde Firestore...',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            );
          } else if (widget.initialReports != null && widget.initialReports!.isNotEmpty) {
            reportsList = widget.initialReports!;
          } else {
            reportsList = [];
          }

          final filtered = _filterReports(reportsList, _selectedFilter);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                sliver: SliverList.list(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 6),
                    Text(
                      'Seguimiento y estado en tiempo real de tus incidencias en la ESPOCH.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    _buildFilterChips(context),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          '${filtered.length} ${filtered.length == 1 ? 'incidencia' : 'incidencias'}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (snapshot.hasData)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'En vivo',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      _buildEmptyState(context)
                    else
                      for (final report in filtered) ...[
                        ReportCard(
                          report: report,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ReportDetailScreen(
                                report: report,
                                auth: currentAuth,
                                firestore: currentFirestore,
                                firestoreService: service,
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

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Mis reportes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.fieBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.fieBlue.withValues(alpha: 0.2),
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
              SizedBox(width: 5),
              Text(
                'Firestore',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fieBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    const filters = ['Todos', 'Pendiente', 'En revisión', 'Resuelto'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: _selectedFilter == filter,
                onSelected: (_) => setState(() => _selectedFilter = filter),
                selectedColor: AppColors.fieBlue.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: _selectedFilter == filter
                      ? AppColors.fieBlue
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: _selectedFilter == filter
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: _selectedFilter == filter
                      ? AppColors.fieBlue.withValues(alpha: 0.3)
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 44,
            color: AppColors.muted.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin incidencias registradas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'Todos'
                ? 'Aún no has reportado problemas en los laboratorios.'
                : 'No existen reportes con estado "$_selectedFilter".',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  List<IncidentReport> _filterReports(
      List<IncidentReport> list, String filter) {
    if (filter == 'Todos') return list;
    return list.where((r) {
      if (filter == 'En revisión') {
        return r.status == ReportStatus.enAtencion;
      }
      return r.statusLabel.toLowerCase() == filter.toLowerCase();
    }).toList();
  }

  IncidentReport _modelToIncident(ReportModel model) {
    final urgencyStr = model.urgency.toLowerCase();
    final statusStr = model.status.toLowerCase();

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

    final shortId = model.reportId.length > 8
        ? (model.reportId.startsWith('REP-') || model.reportId.startsWith('#')
            ? model.reportId
            : '#${model.reportId.substring(0, 8).toUpperCase()}')
        : (model.reportId.startsWith('#') ? model.reportId : '#${model.reportId}');

    return IncidentReport(
      id: shortId,
      building: model.building.isNotEmpty ? model.building : 'FIE',
      laboratory:
          model.laboratory.isNotEmpty ? model.laboratory : 'Laboratorio FIE',
      machine: model.equipmentId.isNotEmpty ? model.equipmentId : 'S/N',
      category: model.category,
      hasEvidence: model.imageUrls.isNotEmpty,
      urgency: urgency,
      description: model.description,
      createdAt: model.createdAt ?? DateTime.now(),
      status: status,
      latitude: model.latitude,
      longitude: model.longitude,
      imageUrls: model.imageUrls,
      resolutionNotes: model.resolutionNotes,
      userId: model.userId,
      assignedTechId: model.assignedTechId,
    );
  }
}

