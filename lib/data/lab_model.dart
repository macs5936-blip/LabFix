import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

enum LabAvailability { activo, mantenimiento, inactivo }

extension LabAvailabilityLabel on LabAvailability {
  String get label => switch (this) {
    LabAvailability.activo => 'Activo',
    LabAvailability.mantenimiento => 'En Mantenimiento',
    LabAvailability.inactivo => 'Fuera de Servicio',
  };
}

class LabRecord {
  const LabRecord({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.technician,
    required this.availability,
    required this.notes,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String location;
  final String capacity;
  final String technician;
  final LabAvailability availability;
  final String notes;
  final double? latitude;
  final double? longitude;
}

abstract final class LabCatalog {
  /// Laboratorios precargados utilizados exclusivamente en pruebas automáticas offline
  static const List<LabRecord> _offlineTestLabs = [
    LabRecord(
      id: 'LAB-REDES',
      name: 'Lab. Redes y Telecomunicaciones',
      location: 'Edificio FIE - Planta Alta, Aula 204',
      capacity: '25 PCs, 2 servidores, 1 proyector',
      technician: 'Carlos Mena',
      availability: LabAvailability.activo,
      notes: 'Rack de comunicaciones y cableado estructurado.',
    ),
    LabRecord(
      id: 'LAB-SOFTWARE-1',
      name: 'Lab. Software #1',
      location: 'Edificio FIE - Planta Baja, Aula 103',
      capacity: '30 PCs, 1 proyector',
      technician: 'David León',
      availability: LabAvailability.activo,
      notes: 'Estaciones para desarrollo y prácticas de software.',
    ),
    LabRecord(
      id: 'LAB-MICRO',
      name: 'Lab. Microprocesadores',
      location: 'Edificio FIE - Planta Alta, Aula 212',
      capacity: '20 PCs, 12 kits de microcontrolador',
      technician: 'Sofía Viteri',
      availability: LabAvailability.mantenimiento,
      notes: 'Revisión preventiva de fuentes y módulos de práctica.',
    ),
    LabRecord(
      id: 'LAB-HARDWARE',
      name: 'Lab. Hardware',
      location: 'Edificio FIE - Planta Baja, Aula 108',
      capacity: '18 PCs, 10 estaciones de diagnóstico',
      technician: 'Carlos Mena',
      availability: LabAvailability.activo,
      notes: 'Herramientas de diagnóstico y reparación de equipos.',
    ),
    LabRecord(
      id: 'LAB-ELECTRONICA',
      name: 'Lab. Electrónica',
      location: 'Edificio FIE - Planta Alta, Aula 218',
      capacity: '20 estaciones, 15 multímetros, 8 osciloscopios',
      technician: 'Sofía Viteri',
      availability: LabAvailability.activo,
      notes: 'Instrumentación para prácticas de circuitos electrónicos.',
    ),
  ];

  static bool get isFirebaseConfigured {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// En producción, inicia completamente vacío para mostrar únicamente los laboratorios
  /// reales creados por el administrador en Firestore.
  static final ValueNotifier<List<LabRecord>> labs = ValueNotifier(
    isFirebaseConfigured ? const <LabRecord>[] : _offlineTestLabs,
  );

  static StreamSubscription<List<LabRecord>>? _subscription;

  /// Vincula la lista de laboratorios en tiempo real con Firestore
  static void syncWithStream(Stream<List<LabRecord>> stream) {
    _subscription?.cancel();
    _subscription = stream.listen((liveLabs) {
      labs.value = List<LabRecord>.of(liveLabs);
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static List<String> get names => [for (final lab in labs.value) lab.name];

  static void save(LabRecord lab) {
    final updated = List<LabRecord>.of(labs.value);
    final index = updated.indexWhere((item) => item.id == lab.id);
    if (index < 0) {
      updated.add(lab);
    } else {
      updated[index] = lab;
    }
    labs.value = updated;
  }

  static void delete(String id) {
    final updated = List<LabRecord>.of(labs.value);
    updated.removeWhere((item) => item.id == id);
    labs.value = updated;
  }

  static void setLabs(List<LabRecord> newLabs) {
    labs.value = List<LabRecord>.of(newLabs);
  }
}
