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
  });

  final String id;
  final String name;
  final String location;
  final String capacity;
  final String technician;
  final LabAvailability availability;
  final String notes;
}

abstract final class LabCatalog {
  static final ValueNotifier<List<LabRecord>> labs = ValueNotifier([
    const LabRecord(
      id: 'LAB-REDES',
      name: 'Lab. Redes y Telecomunicaciones',
      location: 'Edificio FIE - Planta Alta, Aula 204',
      capacity: '25 PCs, 2 servidores, 1 proyector',
      technician: 'Carlos Mena',
      availability: LabAvailability.activo,
      notes: 'Rack de comunicaciones y cableado estructurado.',
    ),
    const LabRecord(
      id: 'LAB-SOFTWARE-1',
      name: 'Lab. Software #1',
      location: 'Edificio FIE - Planta Baja, Aula 103',
      capacity: '30 PCs, 1 proyector',
      technician: 'David León',
      availability: LabAvailability.activo,
      notes: 'Estaciones para desarrollo y prácticas de software.',
    ),
    const LabRecord(
      id: 'LAB-MICRO',
      name: 'Lab. Microprocesadores',
      location: 'Edificio FIE - Planta Alta, Aula 212',
      capacity: '20 PCs, 12 kits de microcontrolador',
      technician: 'Sofía Viteri',
      availability: LabAvailability.mantenimiento,
      notes: 'Revisión preventiva de fuentes y módulos de práctica.',
    ),
    const LabRecord(
      id: 'LAB-HARDWARE',
      name: 'Lab. Hardware',
      location: 'Edificio FIE - Planta Baja, Aula 108',
      capacity: '18 PCs, 10 estaciones de diagnóstico',
      technician: 'Carlos Mena',
      availability: LabAvailability.activo,
      notes: 'Herramientas de diagnóstico y reparación de equipos.',
    ),
    const LabRecord(
      id: 'LAB-ELECTRONICA',
      name: 'Lab. Electrónica',
      location: 'Edificio FIE - Planta Alta, Aula 218',
      capacity: '20 estaciones, 15 multímetros, 8 osciloscopios',
      technician: 'Sofía Viteri',
      availability: LabAvailability.activo,
      notes: 'Instrumentación para prácticas de circuitos electrónicos.',
    ),
  ]);

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
}
