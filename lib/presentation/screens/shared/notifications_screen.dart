import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/report_model.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../student/report_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.reports,
    this.isTechnician = false,
    this.auth,
    this.firestore,
    this.notificationService,
  });

  final List<IncidentReport> reports;
  final bool isTechnician;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final NotificationService? notificationService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_NotificationEntry>? _localEntries;

  FirebaseAuth? get _currentAuth {
    if (widget.auth != null) return widget.auth;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _currentFirestore {
    if (widget.firestore != null) return widget.firestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  NotificationService get _service {
    return widget.notificationService ??
        NotificationService(firestore: _currentFirestore);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Reciente';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<_NotificationEntry> _buildEntriesFromReports() {
    final entries = <_NotificationEntry>[];
    for (var index = 0; index < widget.reports.length; index++) {
      final report = widget.reports[index];
      final isResolved = report.status == ReportStatus.resuelto;
      final isAssigned = report.status == ReportStatus.enAtencion;
      entries.add(
        _NotificationEntry(
          id: 'report-notif-$index',
          kind: _NotificationKind.ticket,
          title: isResolved
              ? 'Ticket resuelto'
              : isAssigned
                  ? 'Actualización de ticket'
                  : 'Reporte registrado',
          description:
              '${report.id} · ${report.laboratory} · ${report.statusLabel}',
          time: index == 0
              ? 'Hace 15 min'
              : index == 1
                  ? 'Ayer'
                  : 'Hace 2 días',
          icon: isResolved
              ? Icons.check_circle_outline
              : Icons.confirmation_number_outlined,
          color: isResolved ? AppColors.green : AppColors.fieBlue,
          report: report,
        ),
      );
      for (final message in report.messages) {
        entries.add(
          _NotificationEntry(
            id: 'report-msg-${report.id}-${message.sentAt.millisecondsSinceEpoch}',
            kind: _NotificationKind.ticket,
            title: 'Nuevo comentario en tu ticket',
            description: '${report.id} · ${message.author}: ${message.body}',
            time: 'Hace 15 min',
            icon: Icons.chat_bubble_outline,
            color: AppColors.fieBlue,
            report: report,
          ),
        );
      }
    }

    entries.addAll([
      _NotificationEntry(
        id: 'lab-notif-1',
        kind: _NotificationKind.laboratory,
        title: 'Mantenimiento de red programado',
        description:
            'La red del Lab. Redes y Telecomunicaciones tendrá una pausa el viernes de 16:00 a 17:00.',
        time: 'Hace 15 min',
        icon: Icons.build_outlined,
        color: AppColors.fieBlue,
      ),
      _NotificationEntry(
        id: 'lab-notif-2',
        kind: _NotificationKind.laboratory,
        title: 'Calibración de equipos',
        description:
            'Los instrumentos del Lab. Electrónica estarán en calibración esta semana.',
        time: 'Ayer',
        icon: Icons.precision_manufacturing_outlined,
        color: AppColors.fieBlue,
      ),
      _NotificationEntry(
        id: 'lab-notif-3',
        kind: _NotificationKind.laboratory,
        title: 'Aviso de laboratorio',
        description:
            'El Lab. Microprocesadores tendrá suspensión temporal por mantenimiento preventivo.',
        time: 'Hace 2 días',
        icon: Icons.campaign_outlined,
        color: AppColors.yellow,
      ),
    ]);
    return entries;
  }

  void _markAllAsRead(List<_NotificationEntry> currentEntries) {
    setState(() {
      for (final entry in currentEntries) {
        entry.isRead = true;
      }
    });

    final user = _currentAuth?.currentUser;
    final uid = user?.uid ?? (widget.isTechnician ? 'TECHNICIAN' : '');
    if (_currentFirestore != null) {
      _service.markAllAsRead(uid).catchError((e) {
        debugPrint('Aviso al marcar notificaciones como leídas: $e');
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas las notificaciones marcadas como leídas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openEntry(_NotificationEntry entry) {
    setState(() => entry.isRead = true);

    if (entry.id.isNotEmpty && _currentFirestore != null) {
      _service.markAsRead(entry.id).catchError((e) {
        debugPrint('Aviso al marcar notificación leída: $e');
      });
    }

    final report = entry.report;
    if (report != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReportDetailScreen(
            report: report,
            isTechnician: widget.isTechnician,
            auth: _currentAuth,
            firestore: _currentFirestore,
          ),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(entry.icon, color: entry.color),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.title, style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.description, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                'Fecha: ${entry.time}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  List<_NotificationEntry> _filterEntries(
    List<_NotificationEntry> entries,
    int tabIndex,
  ) {
    return entries.where((entry) {
      return switch (tabIndex) {
        1 => entry.kind == _NotificationKind.ticket,
        2 => entry.kind == _NotificationKind.laboratory,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentAuth?.currentUser;
    final uid = user?.uid ?? (widget.isTechnician ? 'TECHNICIAN' : 'student_espoch_01');

    Stream<List<NotificationModel>>? stream;
    if (_currentFirestore != null) {
      try {
        stream = widget.isTechnician
            ? _service.getTechnicianNotifications(uid)
            : _service.getStudentNotifications(uid);
      } catch (_) {
        stream = null;
      }
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: stream,
      builder: (context, snapshot) {
        List<_NotificationEntry> entries;

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          entries = snapshot.data!.map((notif) {
            final isTicket = notif.reportId != null && notif.reportId!.trim().isNotEmpty;
            final isResolved = notif.title.toLowerCase().contains('resuelto') ||
                notif.title.toLowerCase().contains('solucionado');

            IncidentReport? linkedReport;
            if (isTicket) {
              final cleanReportId = notif.reportId!.trim();
              for (final r in widget.reports) {
                if (r.id == cleanReportId ||
                    r.id == '#$cleanReportId' ||
                    r.rawDocId == cleanReportId) {
                  linkedReport = r;
                  break;
                }
              }
              linkedReport ??= IncidentReport(
                id: cleanReportId.startsWith('#') ? cleanReportId : '#$cleanReportId',
                building: 'FIE',
                laboratory: 'Laboratorio FIE',
                machine: 'Equipo',
                urgency: Urgency.media,
                description: notif.body,
                createdAt: notif.createdAt ?? DateTime.now(),
                status: isResolved ? ReportStatus.resuelto : ReportStatus.enAtencion,
                rawDocId: cleanReportId.replaceFirst('#', ''),
              );
            }

            final icon = isTicket
                ? (isResolved
                    ? Icons.check_circle_outline
                    : Icons.confirmation_number_outlined)
                : (notif.title.toLowerCase().contains('mantenimiento')
                    ? Icons.build_outlined
                    : (notif.title.toLowerCase().contains('calibración') ||
                            notif.title.toLowerCase().contains('calibracion')
                        ? Icons.precision_manufacturing_outlined
                        : Icons.campaign_outlined));

            final color = isResolved
                ? AppColors.green
                : (isTicket ? AppColors.fieBlue : AppColors.yellow);

            final entry = _NotificationEntry(
              id: notif.notificationId,
              kind: isTicket ? _NotificationKind.ticket : _NotificationKind.laboratory,
              title: notif.title,
              description: notif.body,
              time: _formatTime(notif.createdAt),
              icon: icon,
              color: color,
              report: linkedReport,
            );
            entry.isRead = notif.isRead;
            return entry;
          }).toList();
        } else if (snapshot.connectionState == ConnectionState.waiting &&
            _currentFirestore != null &&
            user != null) {
          // Cargando datos en vivo de Firestore
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.fieBlue,
              foregroundColor: Colors.white,
              title: const Text('Notificaciones y Avisos FIE'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.fieBlue),
                  SizedBox(height: 12),
                  Text('Cargando notificaciones...'),
                ],
              ),
            ),
          );
        } else {
          // Fallback seguro para entorno offline o widget tests
          _localEntries ??= _buildEntriesFromReports();
          entries = _localEntries!;
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.fieBlue,
              foregroundColor: Colors.white,
              title: const Text(
                'Notificaciones y Avisos FIE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  key: const Key('mark-all-notifications-read'),
                  tooltip: 'Marcar todas como leídas',
                  onPressed: () => _markAllAsRead(entries),
                  icon: const Icon(Icons.done_all),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Todas'),
                  Tab(text: 'Mis Tickets'),
                  Tab(text: 'Laboratorios'),
                ],
                indicatorColor: AppColors.gold,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
              ),
            ),
            body: TabBarView(
              children: [
                for (var tabIndex = 0; tabIndex < 3; tabIndex++)
                  _NotificationList(
                    entries: _filterEntries(entries, tabIndex),
                    onTap: _openEntry,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _NotificationKind { ticket, laboratory }

class _NotificationEntry {
  _NotificationEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    this.report,
  });

  final String id;
  final _NotificationKind kind;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  final IncidentReport? report;
  bool isRead = false;
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.entries, required this.onTap});

  final List<_NotificationEntry> entries;
  final ValueChanged<_NotificationEntry> onTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.fieBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 28,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No hay notificaciones en esta sección',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.fieBlueDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Los avisos sobre el estado de tus reportes y novedades de los laboratorios aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('notification-${entry.title}-$index'),
            onTap: () => onTap(entry),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 21),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          entry.time,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!entry.isRead) ...[
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: AppColors.fieBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
