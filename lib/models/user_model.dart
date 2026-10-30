import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para Usuarios en LabFix (ESPOCH)
/// Soporta roles: 'STUDENT', 'TECHNICIAN', 'ADMIN', 'DEANERY'
class UserModel {
  const UserModel({
    required this.uid,
    required this.nombres,
    required this.apellidos,
    required this.email,
    this.cedula = '',
    this.codigoEstudiante = '',
    this.carrera = '',
    this.pao = '',
    this.rol = 'STUDENT',
    this.fotoUrl,
    this.createdAt,
    this.assignedLabs = const [],
  });

  final String uid;
  final String nombres;
  final String apellidos;
  final String email;
  final String cedula;
  final String codigoEstudiante;
  final String carrera;
  final String pao;
  final String rol;
  final String? fotoUrl;
  final DateTime? createdAt;
  /// Lista de nombres de laboratorios asignados al técnico.
  /// Vacía para roles que no son TECHNICIAN.
  final List<String> assignedLabs;

  String get displayName {
    final full = '$nombres $apellidos'.trim();
    return full.isNotEmpty ? full : email;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombres': nombres,
      'apellidos': apellidos,
      'displayName': displayName,
      'email': email,
      'cedula': cedula,
      'codigoEstudiante': codigoEstudiante,
      'carrera': carrera,
      'pao': pao,
      'rol': rol.toUpperCase(),
      'role': rol.toLowerCase(), // Compatibilidad con vistas previas ('student', 'technician', 'admin')
      'fotoUrl': fotoUrl,
      'assignedLabs': assignedLabs,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rolValue = (map['rol'] as String?) ??
        (map['role'] as String?)?.toUpperCase() ??
        'STUDENT';

    return UserModel(
      uid: docId ?? (map['uid'] as String? ?? ''),
      nombres: map['nombres'] as String? ?? '',
      apellidos: map['apellidos'] as String? ?? '',
      email: map['email'] as String? ?? '',
      cedula: map['cedula'] as String? ?? '',
      codigoEstudiante: map['codigoEstudiante'] as String? ?? '',
      carrera: map['carrera'] as String? ?? '',
      pao: map['pao'] as String? ?? '',
      rol: rolValue.toUpperCase(),
      fotoUrl: map['fotoUrl'] as String? ?? map['photoUrl'] as String?,
      createdAt: parseDateTime(map['createdAt']),
      assignedLabs: (map['assignedLabs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  UserModel copyWith({
    String? uid,
    String? nombres,
    String? apellidos,
    String? email,
    String? cedula,
    String? codigoEstudiante,
    String? carrera,
    String? pao,
    String? rol,
    String? fotoUrl,
    DateTime? createdAt,
    List<String>? assignedLabs,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      cedula: cedula ?? this.cedula,
      codigoEstudiante: codigoEstudiante ?? this.codigoEstudiante,
      carrera: carrera ?? this.carrera,
      pao: pao ?? this.pao,
      rol: rol ?? this.rol,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
      assignedLabs: assignedLabs ?? this.assignedLabs,
    );
  }
}

