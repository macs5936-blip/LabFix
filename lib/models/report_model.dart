import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Incidencia / Reporte para LabFix (ESPOCH)
/// Soporta geolocalización en campus, evidencias fotográficas, seguimiento técnico y resolución.
class ReportModel {
  const ReportModel({
    required this.reportId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.building,
    required this.laboratory,
    required this.equipmentId,
    this.latitude,
    this.longitude,
    required this.category,
    required this.description,
    this.urgency = 'Media',
    this.status = 'Pendiente',
    this.imageUrls = const [],
    this.assignedTechId,
    this.resolutionNotes,
    this.createdAt,
    this.updatedAt,
  });

  final String reportId;
  final String userId;
  final String userName;
  final String userEmail;
  final String building; // ej. 'FIE', 'Ciencias Básicas'
  final String laboratory;
  final String equipmentId;
  final double? latitude;
  final double? longitude;
  final String category;
  final String description;
  final String urgency; // 'Baja', 'Media', 'Alta'
  final String status; // 'Pendiente', 'En revisión', 'Resuelto', 'Cancelado'
  final List<String> imageUrls;
  final String? assignedTechId;
  final String? resolutionNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'userId': userId,
      'createdBy': userId, // Compatibilidad con consultas previas
      'userName': userName,
      'userEmail': userEmail,
      'building': building,
      'laboratory': laboratory,
      'equipmentId': equipmentId,
      'machine': equipmentId, // Compatibilidad con vistas previas
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'description': description,
      'urgency': urgency,
      'status': status,
      'imageUrls': imageUrls,
      'hasEvidence': imageUrls.isNotEmpty,
      'assignedTechId': assignedTechId,
      'resolutionNotes': resolutionNotes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    List<String> parseImages(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return ReportModel(
      reportId: docId ?? (map['reportId'] as String? ?? ''),
      userId: map['userId'] as String? ?? map['createdBy'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      building: map['building'] as String? ?? 'FIE',
      laboratory: map['laboratory'] as String? ?? '',
      equipmentId: map['equipmentId'] as String? ?? map['machine'] as String? ?? '',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      category: map['category'] as String? ?? 'General',
      description: map['description'] as String? ?? '',
      urgency: map['urgency'] as String? ?? 'Media',
      status: map['status'] as String? ?? 'Pendiente',
      imageUrls: parseImages(map['imageUrls']),
      assignedTechId: map['assignedTechId'] as String?,
      resolutionNotes: map['resolutionNotes'] as String?,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  ReportModel copyWith({
    String? reportId,
    String? userId,
    String? userName,
    String? userEmail,
    String? building,
    String? laboratory,
    String? equipmentId,
    double? latitude,
    double? longitude,
    String? category,
    String? description,
    String? urgency,
    String? status,
    List<String>? imageUrls,
    String? assignedTechId,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      building: building ?? this.building,
      laboratory: laboratory ?? this.laboratory,
      equipmentId: equipmentId ?? this.equipmentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      assignedTechId: assignedTechId ?? this.assignedTechId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

