import 'dart:ui';

import '../config/theme/app_theme.dart';
import '../models/report_model.dart';

enum Urgency { baja, media, alta }

enum ReportStatus { pendiente, enAtencion, resuelto }

class IncidentReport {
  IncidentReport({
    required this.id,
    this.rawDocId,
    required this.building,
    required this.laboratory,
    required this.machine,
    this.category,
    this.hasEvidence = false,
    required this.urgency,
    required this.description,
    required this.createdAt,
    required this.status,
    List<TicketMessage> messages = const [],
    this.latitude,
    this.longitude,
    this.imageUrls = const [],
    this.resolutionNotes,
    this.userId,
    this.assignedTechId,
  }) : messages = List<TicketMessage>.of(messages);

  final String id;
  /// ID original del documento en Cloud Firestore (ej. 'REP-ESPOCH-001')
  final String? rawDocId;
  final String building;
  final String laboratory;
  final String machine;
  final String? category;
  final bool hasEvidence;
  final Urgency urgency;
  final String description;
  final DateTime createdAt;
  final ReportStatus status;
  final List<TicketMessage> messages;
  /// Coordenada GPS seleccionada en el mapa del campus (opcional).
  final double? latitude;
  final double? longitude;
  /// URLs públicas de fotos de evidencia en Firebase Storage.
  final List<String> imageUrls;
  /// Notas de resolución emitidas por el técnico asignado.
  final String? resolutionNotes;
  final String? userId;
  final String? assignedTechId;

  String get urgencyLabel => switch (urgency) {
    Urgency.baja => 'Baja',
    Urgency.media => 'Media',
    Urgency.alta => 'Alta',
  };

  String get statusLabel => switch (status) {
    ReportStatus.pendiente => 'Pendiente',
    ReportStatus.enAtencion => 'En atención',
    ReportStatus.resuelto => 'Resuelto',
  };

  /// Etiqueta visible en la interfaz estudiantil ('En revisión' o 'En atención')
  String get displayStatusLabel => switch (status) {
    ReportStatus.pendiente => 'Pendiente',
    ReportStatus.enAtencion => 'En revisión',
    ReportStatus.resuelto => 'Resuelto',
  };

  Color get urgencyColor => switch (urgency) {
    Urgency.baja => AppColors.green,
    Urgency.media => AppColors.yellow,
    Urgency.alta => AppColors.red,
  };

  Color get statusColor => switch (status) {
    ReportStatus.pendiente => AppColors.yellow,
    ReportStatus.enAtencion => AppColors.fieBlue,
    ReportStatus.resuelto => AppColors.green,
  };

  factory IncidentReport.fromReportModel(ReportModel model) {
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
      rawDocId: model.reportId,
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

class TicketMessage {
  const TicketMessage({
    required this.author,
    required this.body,
    required this.sentAt,
    required this.isTechnician,
    this.senderId,
  });

  final String author;
  final String body;
  final DateTime sentAt;
  final bool isTechnician;
  final String? senderId;
}

final List<IncidentReport> mockReports = [
  IncidentReport(
    id: 'INC-0248',
    building: 'FIE',
    laboratory: 'Lab. Redes',
    machine: '12',
    urgency: Urgency.alta,
    description: 'El equipo no reconoce la conexión de red.',
    createdAt: DateTime(2026, 9, 28),
    status: ReportStatus.enAtencion,
  ),
  IncidentReport(
    id: 'INC-0241',
    building: 'FIE',
    laboratory: 'Lab. Software',
    machine: '08',
    urgency: Urgency.media,
    description: 'El entorno de desarrollo no compila la práctica.',
    createdAt: DateTime(2026, 9, 24),
    status: ReportStatus.pendiente,
  ),
  IncidentReport(
    id: 'INC-0233',
    building: 'FIE',
    laboratory: 'Lab. Hardware',
    machine: '21',
    urgency: Urgency.baja,
    description: 'El puerto USB del equipo no reconoce dispositivos.',
    createdAt: DateTime(2026, 9, 20),
    status: ReportStatus.resuelto,
  ),
];

String formatReportDate(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Extensión de conveniencia para convertir [ReportModel] al modelo de
/// presentación [IncidentReport] sin importaciones circulares.
extension ReportModelToIncident on ReportModel {
  IncidentReport toIncidentReport() => IncidentReport.fromReportModel(this);
}
