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
    this.customDisplayName,
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
  final String? customDisplayName;

  String get displayName {
    final full = '$nombres $apellidos'.trim();
    if (full.isNotEmpty) return full;
    if (customDisplayName != null && customDisplayName!.trim().isNotEmpty) {
      return customDisplayName!.trim();
    }
    // Si no hay nombres pero hay correo, intentar extraer un nombre legible del correo
    if (email.isNotEmpty && email.contains('@')) {
      final username = email.split('@').first;
      final clean = username.replaceAll(RegExp(r'[0-9._-]+'), ' ').trim();
      if (clean.length >= 3) {
        final words = clean
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
            .join(' ');
        if (words.isNotEmpty) return words;
      }
    }
    return email;
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

    String nombres = (map['nombres'] as String?)?.trim() ?? '';
    String apellidos = (map['apellidos'] as String?)?.trim() ?? '';
    final rawDisplayName = (map['displayName'] as String?)?.trim() ??
        (map['name'] as String?)?.trim() ??
        (map['nombreCompleto'] as String?)?.trim() ??
        (map['nombre'] as String?)?.trim() ??
        '';

    // Para usuarios que inician sesión con Google o Microsoft, es común que Firestore
    // contenga 'displayName' pero no 'nombres' ni 'apellidos'. Los descomponemos aquí:
    if (nombres.isEmpty && apellidos.isEmpty && rawDisplayName.isNotEmpty) {
      final parts = rawDisplayName
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length == 1) {
        nombres = parts[0];
      } else if (parts.length == 2) {
        nombres = parts[0];
        apellidos = parts[1];
      } else if (parts.length > 2) {
        final half = parts.length ~/ 2;
        nombres = parts.take(half).join(' ');
        apellidos = parts.skip(half).join(' ');
      }
    }

    return UserModel(
      uid: docId ?? (map['uid'] as String? ?? ''),
      nombres: nombres,
      apellidos: apellidos,
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
      customDisplayName: rawDisplayName.isNotEmpty ? rawDisplayName : null,
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
    String? customDisplayName,
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
      customDisplayName: customDisplayName ?? this.customDisplayName,
    );
  }
}

