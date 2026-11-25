import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../config/theme/app_theme.dart';
import '../../../data/lab_model.dart';
import '../../../data/report_model.dart' show mockReports;
import '../../../models/report_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/location_picker_modal.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    super.key,
    required this.onLogout,
    this.firestoreService,
  });

  final ValueChanged<BuildContext> onLogout;
  final FirestoreService? firestoreService;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();

  bool get _isFirebaseReady {
    if (widget.firestoreService != null) return true;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _period = 'Este Mes';
  String _userSearch = '';
  String _selectedLab = 'Lab. Redes y Telecomunicaciones';
  String _selectedTechnician = 'Carlos Mena';

  final List<UserModel> _fallbackUsers = [
    const UserModel(
      uid: 'user_fallback_01',
      nombres: 'Ana',
      apellidos: 'Paredes',
      email: 'ana.paredes@espoch.edu.ec',
      codigoEstudiante: 'EST-FIE-2024-018',
      rol: 'STUDENT',
    ),
    const UserModel(
      uid: 'user_fallback_02',
      nombres: 'Luis',
      apellidos: 'Cárdenas',
      email: 'luis.cardenas@espoch.edu.ec',
      codigoEstudiante: 'EST-FIE-2023-076',
      rol: 'STUDENT',
    ),
    const UserModel(
      uid: 'user_fallback_03',
      nombres: 'Carlos',
      apellidos: 'Mena',
      email: 'carlos.mena@espoch.edu.ec',
      codigoEstudiante: 'TEC-FIE-014',
      rol: 'TECHNICIAN',
    ),
    const UserModel(
      uid: 'user_fallback_04',
      nombres: 'Sofía',
      apellidos: 'Viteri',
      email: 'sofia.viteri@espoch.edu.ec',
      codigoEstudiante: 'TEC-FIE-022',
      rol: 'TECHNICIAN',
    ),
    const UserModel(
      uid: 'user_fallback_05',
      nombres: 'David',
      apellidos: 'León',
      email: 'david.leon@espoch.edu.ec',
      codigoEstudiante: 'TEC-FIE-031',
      rol: 'TECHNICIAN',
    ),
  ];

  final Map<String, List<_ScheduleBlock>> _schedules = {
    'Lab. Redes y Telecomunicaciones': [
      _ScheduleBlock('Lunes', '08:00 - 10:00', 'Redes I', 'Ing. Carlos Mena'),
      _ScheduleBlock(
        'Miércoles',
        '10:00 - 12:00',
        'Telemática',
        'Mgs. Ana Ruiz',
      ),
      _ScheduleBlock(
        'Viernes',
        '14:00 - 16:00',
        'Redes II',
        'Ing. Carlos Mena',
      ),
    ],
    'Lab. Software #1': [
      _ScheduleBlock(
        'Martes',
        '08:00 - 10:00',
        'Programación',
        'Mgs. Elena Paz',
      ),
      _ScheduleBlock(
        'Jueves',
        '12:00 - 14:00',
        'Sistemas Operativos',
        'Ing. David León',
      ),
    ],
    'Lab. Microprocesadores': [
      _ScheduleBlock(
        'Lunes',
        '14:00 - 16:00',
        'Arquitectura',
        'Ing. Sofía Viteri',
      ),
      _ScheduleBlock(
        'Jueves',
        '08:00 - 10:00',
        'Microcontroladores',
        'Ing. Sofía Viteri',
      ),
    ],
    'Lab. Hardware': [],
    'Lab. Electrónica': [],
  };

  static const _technicianStatsByName = {
    'Carlos Mena': _TechnicianStats(
      attended: 38,
      resolved: 34,
      pending: 4,
      responseTime: '18 min',
      resolutionTime: '3.6 h',
      rating: '4.8 / 5',
    ),
    'Sofía Viteri': _TechnicianStats(
      attended: 31,
      resolved: 28,
      pending: 3,
      responseTime: '24 min',
      resolutionTime: '4.1 h',
      rating: '4.6 / 5',
    ),
    'David León': _TechnicianStats(
      attended: 26,
      resolved: 22,
      pending: 4,
      responseTime: '31 min',
      resolutionTime: '4.8 h',
      rating: '4.4 / 5',
    ),
  };

  static const _technicianHistoryByName = {
    'Carlos Mena': [
      'Resuelto · Lab. Redes · Configuración de puerto Ethernet',
      'Resuelto · Lab. Hardware · Diagnóstico de equipo PC-08',
      'En atención · Lab. Software #1 · Error de licencia',
    ],
    'Sofía Viteri': [
      'Resuelto · Lab. Microprocesadores · Revisión de fuente de poder',
      'Resuelto · Lab. Electrónica · Calibración de multímetro',
      'En atención · Lab. Hardware · Equipo sin señal de video',
    ],
    'David León': [
      'Resuelto · Lab. Software #1 · Recuperación de entorno de desarrollo',
      'Resuelto · Lab. Redes · Configuración de switch',
      'Pendiente · Lab. Software #1 · Renovación de licencia',
    ],
  };

  static const _fallbackPeriodMetrics = {
    'Esta Semana': _PeriodMetrics(
      incidents: '11',
      resolution: '3.8 h',
      availability: '96.2%',
      failures: [24, 32, 28, 16],
    ),
    'Este Mes': _PeriodMetrics(
      incidents: '42',
      resolution: '4.2 h',
      availability: '94.5%',
      failures: [36, 29, 21, 14],
    ),
    'Este Semestre': _PeriodMetrics(
      incidents: '128',
      resolution: '5.1 h',
      availability: '92.8%',
      failures: [31, 27, 24, 18],
    ),
  };

  _PeriodMetrics get _metrics => _fallbackPeriodMetrics[_period]!;

  _TechnicianStats get _technicianStats =>
      _technicianStatsMap[_selectedTechnician]!;

  Map<String, _TechnicianStats> get _technicianStatsMap =>
      _technicianStatsByName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (_isFirebaseReady) {
      LabCatalog.syncWithStream(_firestoreService.streamLaboratories());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _LiveMetrics _calculateLiveMetrics(List<ReportModel> allReports, String period) {
    final now = DateTime.now();
    final periodReports = allReports.where((r) {
      final date = r.createdAt;
      if (date == null) return true;
      final diff = now.difference(date);
      return switch (period) {
        'Esta Semana' => diff.inDays <= 7,
        'Este Mes' => diff.inDays <= 30,
        'Este Semestre' => diff.inDays <= 180,
        _ => true,
      };
    }).toList();

    final total = periodReports.length;

    // 1. Tiempo promedio de resolución
    final resolvedReports = periodReports.where((r) {
      final s = r.status.trim().toLowerCase();
      return s == 'resuelto' || s == 'resolved';
    }).toList();

    String resolutionStr = '--';
    if (resolvedReports.isNotEmpty) {
      var totalMinutes = 0;
      var count = 0;
      for (final r in resolvedReports) {
        if (r.createdAt != null && r.updatedAt != null) {
          final diff = r.updatedAt!.difference(r.createdAt!).inMinutes.abs();
          if (diff > 0) {
            totalMinutes += diff;
            count++;
          }
        }
      }
      if (count > 0) {
        final avgHours = totalMinutes / (count * 60.0);
        resolutionStr = avgHours >= 1.0
            ? '${avgHours.toStringAsFixed(1)} h'
            : '${(avgHours * 60).round()} min';
      } else {
        resolutionStr = '0.5 h';
      }
    } else if (total > 0) {
      resolutionStr = 'En atención';
    }

    // 2. Laboratorio con mayor tasa de fallos
    String worstLab = 'Sin fallos';
    if (total > 0) {
      final labCounts = <String, int>{};
      for (final r in periodReports) {
        final lab = r.laboratory.trim();
        if (lab.isNotEmpty) {
          labCounts[lab] = (labCounts[lab] ?? 0) + 1;
        }
      }
      if (labCounts.isNotEmpty) {
        var maxCount = 0;
        labCounts.forEach((lab, c) {
          if (c > maxCount) {
            maxCount = c;
            worstLab = lab.replaceAll('Lab. ', '').trim();
          }
        });
      }
    }

    // 3. Disponibilidad de equipos
    String availabilityStr = '100%';
    if (total > 0) {
      final openCount = periodReports.where((r) {
        final s = r.status.trim().toLowerCase();
        return s != 'resuelto' && s != 'resolved' && s != 'cancelado';
      }).length;
      final pct = (100.0 - (openCount * 3.0)).clamp(75.0, 100.0);
      availabilityStr = '${pct.toStringAsFixed(1)}%';
    }

    // 4. Distribución por tipo de fallo
    int hwPct = 0;
    int swPct = 0;
    int netPct = 0;
    int infraPct = 0;

    if (total > 0) {
      var hw = 0;
      var sw = 0;
      var net = 0;
      var infra = 0;

      for (final r in periodReports) {
        final cat = (r.category.isNotEmpty ? r.category : r.description).toLowerCase();
        if (cat.contains('hard') || cat.contains('disco') || cat.contains('pantalla') || cat.contains('fuente') || cat.contains('mouse') || cat.contains('teclado')) {
          hw++;
        } else if (cat.contains('soft') || cat.contains('sistema') || cat.contains('windows') || cat.contains('linux') || cat.contains('licencia') || cat.contains('virtual')) {
          sw++;
        } else if (cat.contains('red') || cat.contains('conect') || cat.contains('wifi') || cat.contains('internet') || cat.contains('cable') || cat.contains('switch')) {
          net++;
        } else {
          infra++;
        }
      }

      hwPct = ((hw / total) * 100).round();
      swPct = ((sw / total) * 100).round();
      netPct = ((net / total) * 100).round();
      infraPct = ((infra / total) * 100).round();
    }

    return _LiveMetrics(
      incidentsCount: '$total',
      resolutionTime: resolutionStr,
      worstLab: worstLab,
      availability: availabilityStr,
      hardwarePct: hwPct,
      softwarePct: swPct,
      networkPct: netPct,
      infraPct: infraPct,
      totalInPeriod: total,
    );
  }

  Future<void> _showExportDialog([int? count]) async {
    final extra = count != null ? ' con $count incidencias' : '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.task_alt_outlined,
          color: AppColors.fieBlue,
          size: 38,
        ),
        title: const Text('Informe preparado'),
        content: Text(
          'El informe general de $_period$extra está listo para descargar en PDF / Excel. (Descarga simulada)',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_sweep_outlined,
          color: AppColors.red,
          size: 40,
        ),
        title: const Text('Vaciar Colecciones'),
        content: const Text(
          '¿Deseas vaciar todas las colecciones de prueba (reportes, laboratorios, horarios, notificaciones, etc.) de la base de datos?\n\n'
          '✅ IMPORTANTE: La colección de USUARIOS quedará intacta y ningún usuario registrado será eliminado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, Vaciar Colecciones'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Vaciando colecciones en Cloud Firestore...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final result = await _firestoreService.clearAllCollectionsExceptUsers();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Cierra loading
          final total = result.values.fold<int>(0, (sum, c) => sum + c);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vaciado exitoso: $total documentos eliminados. Colección de usuarios conservada intacta.',
              ),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Cierra loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al vaciar colecciones: $e'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildUsersTab() {
    if (!_isFirebaseReady) {
      return _buildUsersList(_fallbackUsers);
    }

    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? const <UserModel>[];
        if (users.isEmpty && !snapshot.hasData) {
          return _buildUsersList(_fallbackUsers);
        }
        return _buildUsersList(users);
      },
    );
  }

  Widget _buildUsersList(List<UserModel> usersList) {
    final query = _userSearch.trim().toLowerCase();
    final visibleUsers = usersList.where((user) {
      final name = user.displayName.toLowerCase();
      final email = user.email.toLowerCase();
      final code = user.codigoEstudiante.toLowerCase();
      final cedula = user.cedula.toLowerCase();
      return query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          code.contains(query) ||
          cedula.contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text(
          'Gestión de Usuarios',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          'Busca por nombre, correo institucional o Código Central.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('admin-user-search'),
          onChanged: (value) => setState(() => _userSearch = value),
          decoration: const InputDecoration(
            hintText: 'Nombre, correo o código',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.manage_search_outlined),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${visibleUsers.length} usuarios',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (visibleUsers.isEmpty)
          _AdminEmptyState(
            icon: Icons.person_search_outlined,
            message: query.isEmpty
                ? 'No hay usuarios registrados en la base de datos.'
                : 'No se encontraron usuarios para "$query".',
          )
        else
          for (final user in visibleUsers) ...[
            _buildUserCard(user),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    final cleanRole = AuthService.normalizeRole(user.rol);
    final initialDropdownValue = switch (cleanRole) {
      'admin' => 'Administrador',
      'technician' => 'Técnico',
      _ => 'Estudiante',
    };

    final displayCode = user.codigoEstudiante.isNotEmpty
        ? user.codigoEstudiante
        : (user.cedula.isNotEmpty
            ? 'CI: ${user.cedula}'
            : (user.uid.length >= 8 ? 'ID: ${user.uid.substring(0, 8)}' : user.uid));

    final userKeyId = user.codigoEstudiante.isNotEmpty ? user.codigoEstudiante : user.uid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.fieBlue.withValues(alpha: 0.1),
              foregroundColor: AppColors.fieBlue,
              child: Text(
                _initials(user.displayName.isNotEmpty ? user.displayName : user.email),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : user.email,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (displayCode.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      displayCode,
                      style: const TextStyle(
                        color: AppColors.fieBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                key: Key('role-$userKeyId'),
                initialValue: initialDropdownValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Estudiante',
                    child: Text('Estudiante'),
                  ),
                  DropdownMenuItem(
                    value: 'Técnico',
                    child: Text('Técnico'),
                  ),
                  DropdownMenuItem(
                    value: 'Administrador',
                    child: Text('Administrador'),
                  ),
                ],
                onChanged: (selectedLabel) async {
                  if (selectedLabel == null || selectedLabel == initialDropdownValue) return;

                  final newRole = switch (selectedLabel) {
                    'Administrador' => 'admin',
                    'Técnico' => 'technician',
                    _ => 'student',
                  };

                  if (_isFirebaseReady) {
                    try {
                      await _firestoreService.updateUserRole(user.uid, newRole);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar en Firestore: $e'),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                      return;
                    }
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Rol de ${user.displayName.isNotEmpty ? user.displayName : user.email} actualizado a $selectedLabel',
                        ),
                        backgroundColor: AppColors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsTab() {
    if (!_isFirebaseReady) {
      return _buildMetricsContent(
        _PeriodMetrics(
          incidents: _metrics.incidents,
          resolution: _metrics.resolution,
          availability: _metrics.availability,
          failures: _metrics.failures,
        ),
        worstLabName: 'Redes y Telecomunicaciones',
        totalIncidents: int.tryParse(_metrics.incidents) ?? 0,
        reportsList: const [],
        isLoading: false,
      );
    }

    return StreamBuilder<List<ReportModel>>(
      stream: _firestoreService.getAllReports(),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? const <ReportModel>[];
        final liveMetrics = _calculateLiveMetrics(reports, _period);

        return _buildMetricsContent(
          _PeriodMetrics(
            incidents: liveMetrics.incidentsCount,
            resolution: liveMetrics.resolutionTime,
            availability: liveMetrics.availability,
            failures: [
              liveMetrics.hardwarePct,
              liveMetrics.softwarePct,
              liveMetrics.networkPct,
              liveMetrics.infraPct,
            ],
          ),
          worstLabName: liveMetrics.worstLab,
          totalIncidents: liveMetrics.totalInPeriod,
          reportsList: reports,
          isLoading: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData,
        );
      },
    );
  }

  Widget _buildMetricsContent(
    _PeriodMetrics metrics, {
    required String worstLabName,
    required int totalIncidents,
    required List<ReportModel> reportsList,
    required bool isLoading,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.fieBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de Gestión y Métricas - FIE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Indicadores globales de laboratorios y soporte en tiempo real',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Indicadores globales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (isLoading)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.insights_outlined, color: AppColors.fieBlue),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 4,
          children: [
            for (final period in ['Esta Semana', 'Este Mes', 'Este Semestre'])
              ChoiceChip(
                key: Key('period-$period'),
                label: Text(period),
                selected: _period == period,
                onSelected: (_) => setState(() => _period = period),
                selectedColor: AppColors.fieBlue.withValues(alpha: 0.12),
                side: BorderSide(
                  color: _period == period
                      ? AppColors.fieBlue.withValues(alpha: 0.3)
                      : AppColors.line,
                ),
                labelStyle: TextStyle(
                  color: _period == period
                      ? AppColors.fieBlue
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Incidencias en el período',
                    value: metrics.incidents,
                    icon: Icons.report_outlined,
                    color: AppColors.fieBlue,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Tiempo promedio de resolución',
                    value: metrics.resolution,
                    icon: Icons.schedule_outlined,
                    color: AppColors.yellow,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Laboratorio con mayor tasa de fallos',
                    value: worstLabName,
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.red,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Disponibilidad de equipos',
                    value: metrics.availability,
                    icon: Icons.check_circle_outline,
                    color: AppColors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          'Distribución por tipo de fallo',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 9),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: totalIncidents == 0
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Sin incidencias registradas en este período.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _FailureBar(
                        label: 'Hardware',
                        percentage: metrics.failures[0],
                        color: AppColors.fieBlue,
                      ),
                      _FailureBar(
                        label: 'Software',
                        percentage: metrics.failures[1],
                        color: AppColors.green,
                      ),
                      _FailureBar(
                        label: 'Red',
                        percentage: metrics.failures[2],
                        color: AppColors.yellow,
                      ),
                      _FailureBar(
                        label: 'Infraestructura / Otros',
                        percentage: metrics.failures[3],
                        color: AppColors.red,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Estado de laboratorios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${LabCatalog.labs.value.length} sedes/aulas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 9),
        ValueListenableBuilder<List<LabRecord>>(
          valueListenable: LabCatalog.labs,
          builder: (context, laboratories, _) => Card(
            child: Column(
              children: [
                for (var index = 0; index < laboratories.length; index++)
                  _buildLiveLabStatusRow(
                    laboratories[index],
                    reportsList,
                    showDivider: index < laboratories.length - 1,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('export-report'),
          onPressed: () => _showExportDialog(totalIncidents),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Exportar Informe General (PDF / Excel)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.fieBlue,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('manage-laboratories-shortcut'),
          onPressed: () => _tabController.animateTo(2),
          icon: const Icon(Icons.domain_add_outlined),
          label: const Text('Registrar Nuevo Laboratorio'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.fieBlue,
            side: const BorderSide(color: AppColors.fieBlue),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveLabStatusRow(
    LabRecord lab,
    List<ReportModel> allReports, {
    required bool showDivider,
  }) {
    final openReportsInLab = allReports.where((r) {
      final matchesLab =
          r.laboratory.toLowerCase().contains(lab.name.toLowerCase()) ||
          lab.name.toLowerCase().contains(r.laboratory.toLowerCase());
      final isPending =
          r.status.toLowerCase() != 'resuelto' &&
          r.status.toLowerCase() != 'resolved' &&
          r.status.toLowerCase() != 'cancelado';
      return matchesLab && isPending;
    }).length;

    var statusLabel = lab.availability.label;
    var statusColor = _availabilityColor(lab.availability);

    if (openReportsInLab > 0 && lab.availability == LabAvailability.activo) {
      statusLabel =
          '$openReportsInLab incidencia${openReportsInLab > 1 ? 's' : ''}';
      statusColor = AppColors.yellow;
    }

    return _LabStatusRow(
      name: lab.name,
      status: statusLabel,
      color: statusColor,
      showDivider: showDivider,
    );
  }

  Widget _buildSchedulesTab() {
    final blocks = _schedules[_selectedLab] ?? const <_ScheduleBlock>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text(
          'Horarios y Disponibilidad',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          'Consulta y actualiza los bloques de uso de cada laboratorio.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const Key('register-laboratory'),
          onPressed: () => _openLaboratoryEditor(),
          icon: const Icon(Icons.domain_add_outlined),
          label: const Text('Registrar Nuevo Laboratorio'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.fieBlue,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<List<LabRecord>>(
          valueListenable: LabCatalog.labs,
          builder: (context, laboratories, _) {
            final hasMatch = laboratories.any((l) => l.name == _selectedLab);
            final effectiveValue = hasMatch
                ? _selectedLab
                : (laboratories.isNotEmpty ? laboratories.first.name : null);

            return DropdownButtonFormField<String>(
              key: const Key('schedule-lab-selector'),
              initialValue: effectiveValue,
              isExpanded: true,
              hint: const Text('No hay laboratorios registrados'),
              decoration: const InputDecoration(
                labelText: 'Laboratorio',
                prefixIcon: Icon(Icons.science_outlined),
              ),
              items: [
                for (final lab in laboratories)
                  DropdownMenuItem(
                    value: lab.name,
                    child: Text(
                      lab.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selectedItemBuilder: (context) => [
                for (final lab in laboratories)
                  SizedBox(
                    width: 150,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        lab.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
              onChanged: (lab) {
                if (lab != null) setState(() => _selectedLab = lab);
              },
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('upload-schedule'),
                onPressed: _showScheduleUploadDialog,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Cargar / Actualizar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.fieBlue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              key: const Key('add-schedule-block'),
              tooltip: 'Añadir bloque horario',
              onPressed: _showAddScheduleDialog,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Text('Día', style: _tableHeaderStyle(context))),
            Expanded(
              child: Text('Bloque horario', style: _tableHeaderStyle(context)),
            ),
          ],
        ),
        const Divider(height: 15),
        if (blocks.isEmpty)
          const _AdminEmptyState(
            icon: Icons.event_busy_outlined,
            message: 'No hay bloques registrados para este laboratorio.',
          )
        else
          for (final block in blocks) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            block.day,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          block.time,
                          style: const TextStyle(
                            color: AppColors.fieBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      block.course,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      block.teacher,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
          ],
        const SizedBox(height: 22),
        _buildLabManagementSection(),
      ],
    );
  }

  Widget _buildLabManagementSection() {
    return ValueListenableBuilder<List<LabRecord>>(
      valueListenable: LabCatalog.labs,
      builder: (context, laboratories, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registro y Gestión de Laboratorios',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                key: const Key('add-lab-from-list'),
                tooltip: 'Registrar laboratorio',
                onPressed: () => _openLaboratoryEditor(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Actualiza ubicación, capacidad, responsable y disponibilidad.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (laboratories.isEmpty)
            Card(
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.science_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No hay laboratorios registrados en la base de datos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Presiona "Registrar Nuevo Laboratorio" o el botón "+" para añadir laboratorios.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            for (final laboratory in laboratories) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 7, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.fieBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.science_outlined,
                        color: AppColors.fieBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            laboratory.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${laboratory.location} · ${laboratory.capacity}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 5),
                          _LabAvailabilityBadge(
                            availability: laboratory.availability,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('edit-lab-${laboratory.id}'),
                          tooltip: 'Editar ${laboratory.name}',
                          onPressed: () => _openLaboratoryEditor(laboratory),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          key: Key('delete-lab-${laboratory.id}'),
                          tooltip: 'Eliminar ${laboratory.name}',
                          onPressed: () => _confirmDeleteLaboratory(laboratory),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Future<List<String>> _fetchTechnicians() async {
    if (_isFirebaseReady) {
      try {
        final users = await _firestoreService.streamAllUsers().first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => const [],
        );
        final techs = users
            .where((u) => AuthService.normalizeRole(u.rol) == 'technician')
            .map((u) => u.displayName.isNotEmpty ? u.displayName : u.email)
            .toList();
        if (techs.isNotEmpty) return techs;
      } catch (_) {}
    }
    return const ['Carlos Mena', 'Sofía Viteri', 'David León'];
  }

  Future<void> _openLaboratoryEditor([LabRecord? existing]) async {
    final technicians = await _fetchTechnicians();
    if (!mounted) return;

    final saved = await showDialog<LabRecord>(
      context: context,
      builder: (_) => _LabEditorDialog(
        laboratory: existing,
        technicians: technicians,
      ),
    );
    if (saved == null || !mounted) return;

    setState(() {
      if (existing != null && existing.name != saved.name) {
        final previousSchedule =
            _schedules.remove(existing.name) ?? <_ScheduleBlock>[];
        _schedules.putIfAbsent(saved.name, () => previousSchedule);
        if (_selectedLab == existing.name) _selectedLab = saved.name;
      } else {
        _schedules.putIfAbsent(saved.name, () => <_ScheduleBlock>[]);
      }
    });
    LabCatalog.save(saved);

    if (_isFirebaseReady) {
      try {
        await _firestoreService.saveLaboratory(saved);
      } catch (e) {
        debugPrint('Aviso al guardar laboratorio en Firestore: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Laboratorio registrado exitosamente'
                : 'Laboratorio actualizado exitosamente',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteLaboratory(LabRecord laboratory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_outlined,
          color: AppColors.red,
          size: 38,
        ),
        title: const Text('¿Eliminar laboratorio?'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${laboratory.name}"?\n\n'
          'Esta acción removerá el laboratorio de la lista y de la base de datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        LabCatalog.delete(laboratory.id);
        _schedules.remove(laboratory.name);
        if (_selectedLab == laboratory.name) {
          _selectedLab = LabCatalog.labs.value.isNotEmpty
              ? LabCatalog.labs.value.first.name
              : '';
        }
      });

      if (_isFirebaseReady) {
        try {
          await _firestoreService.deleteLaboratory(
            laboratory.id,
            laboratory.name,
          );
        } catch (e) {
          debugPrint('Aviso al eliminar laboratorio en Firestore: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laboratorio "${laboratory.name}" eliminado exitosamente.',
            ),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showScheduleUploadDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.upload_file_outlined, color: AppColors.fieBlue),
        title: const Text('Actualizar horario'),
        content: Text(
          'Selecciona un archivo Excel o PDF para $_selectedLab. La carga está simulada en esta versión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Horario de $_selectedLab actualizado (simulación).',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Simular carga'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddScheduleDialog() async {
    final result = await showDialog<_ScheduleBlock>(
      context: context,
      builder: (_) => _AddScheduleDialog(laboratory: _selectedLab),
    );
    if (result == null || !mounted) return;
    setState(() => _schedules[_selectedLab]!.add(result));
  }

  Widget _buildTechnicianPerformanceTab() {
    final stats = _technicianStats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text(
          'Rendimiento de Técnicos',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          'Consulta la actividad individual del equipo de soporte FIE.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 17),
        DropdownButtonFormField<String>(
          key: const Key('technician-selector'),
          initialValue: _selectedTechnician,
          decoration: const InputDecoration(
            labelText: 'Técnico',
            prefixIcon: Icon(Icons.engineering_outlined),
          ),
          items: [
            for (final name in _technicianStatsByName.keys)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: (name) {
            if (name != null) setState(() => _selectedTechnician = name);
          },
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.fieBlue.withValues(alpha: 0.1),
                  foregroundColor: AppColors.fieBlue,
                  child: Text(_initials(_selectedTechnician)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTechnician,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Soporte Técnico · FIE',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.star, color: AppColors.gold, size: 18),
                const SizedBox(width: 3),
                Text(
                  stats.rating,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    label: 'Atendidos',
                    value: '${stats.attended}',
                    icon: Icons.assignment_outlined,
                    color: AppColors.fieBlue,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    label: 'Resueltos',
                    value: '${stats.resolved}',
                    icon: Icons.task_alt_outlined,
                    color: AppColors.green,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    label: 'Pendientes',
                    value: '${stats.pending}',
                    icon: Icons.pending_actions_outlined,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _InfoMetricRow(
                label: 'Tiempo promedio de respuesta',
                value: stats.responseTime,
                icon: Icons.reply_outlined,
              ),
              const Divider(height: 1, indent: 14, endIndent: 14),
              _InfoMetricRow(
                label: 'Tiempo promedio de resolución',
                value: stats.resolutionTime,
                icon: Icons.timer_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Historial reciente',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final item in _technicianHistoryByName[_selectedTechnician]!)
          Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: AppColors.fieBlue),
              title: Text(item),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('export-technician-report'),
          onPressed: _showTechnicianReportDialog,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Descargar Reporte Individual (PDF)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.fieBlue,
            side: const BorderSide(color: AppColors.fieBlue),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _showTechnicianReportDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reporte individual preparado'),
        content: Text(
          'El informe de rendimiento de $_selectedTechnician está listo en PDF. (Descarga simulada)',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return name.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Color _availabilityColor(LabAvailability availability) =>
      switch (availability) {
        LabAvailability.activo => AppColors.green,
        LabAvailability.mantenimiento => AppColors.yellow,
        LabAvailability.inactivo => AppColors.red,
      };

  TextStyle _tableHeaderStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  Future<void> _confirmLogout(BuildContext context) async {
    Navigator.of(context).pop();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas volver a la pantalla de acceso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted && context.mounted) {
      widget.onLogout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Administración FIE',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Abrir menú de administración',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Vaciar colecciones (excepto usuarios)',
            onPressed: _confirmClearDatabase,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => _openNotifications(context),
            icon: const Icon(Icons.notifications_outlined),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.admin_panel_settings_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.insights_outlined), text: 'Métricas'),
            Tab(icon: Icon(Icons.manage_accounts_outlined), text: 'Usuarios'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Horarios'),
            Tab(icon: Icon(Icons.engineering_outlined), text: 'Técnicos'),
          ],
          indicatorColor: AppColors.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMetricsTab(),
          _buildUsersTab(),
          _buildSchedulesTab(),
          _buildTechnicianPerformanceTab(),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
              decoration: const BoxDecoration(color: AppColors.fieBlue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.gold,
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: AppColors.fieBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Administración / Decanato',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'decanato.fie@espoch.edu.ec',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'ROL · ADMINISTRADOR',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notificaciones'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openNotifications(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Panel de métricas'),
                    selected: true,
                    selectedTileColor: AppColors.fieBlue.withValues(
                      alpha: 0.08,
                    ),
                    onTap: () => _selectSection(context, 0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Gestión de Usuarios'),
                    onTap: () => _selectSection(context, 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Horarios de Laboratorios'),
                    onTap: () => _selectSection(context, 2),
                  ),
                  ListTile(
                    leading: const Icon(Icons.engineering_outlined),
                    title: const Text('Rendimiento de Técnicos'),
                    onTap: () => _selectSection(context, 3),
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Exportar informe general'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showExportDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Gestión de laboratorios'),
                    onTap: () => _selectSection(context, 2),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.red),
                    title: const Text(
                      'Vaciar colecciones (Limpiar datos)',
                      style: TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Elimina documentos excepto usuarios',
                      style: TextStyle(fontSize: 10),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _confirmClearDatabase();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Mi Perfil / Ajustes'),
                    onTap: () => _openAdminProfile(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: AppColors.red),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(reports: mockReports),
      ),
    );
  }

  void _selectSection(BuildContext context, int index) {
    Navigator.of(context).pop();
    _tabController.animateTo(index);
  }

  void _openAdminProfile(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileSettingsScreen(
          fullName: 'Administración / Decanato',
          email: 'decanato.fie@espoch.edu.ec',
          role: 'ADMINISTRADOR',
          department: 'Decanato · Facultad de Informática y Electrónica',
          centralCode: 'ADM-FIE-001',
          position: 'Puesto: Administrador',
        ),
      ),
    );
  }
}

class _LabEditorDialog extends StatefulWidget {
  const _LabEditorDialog({
    this.laboratory,
    this.technicians = const [],
  });

  final LabRecord? laboratory;
  final List<String> technicians;

  @override
  State<_LabEditorDialog> createState() => _LabEditorDialogState();
}

class _LabEditorDialogState extends State<_LabEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _notesController;
  late String? _technician;
  late LabAvailability _availability;
  LatLng? _pickedLatLng;

  static const _defaultTechnicians = ['Carlos Mena', 'Sofía Viteri', 'David León'];

  List<String> get _technicianList {
    final list = List<String>.from(
      widget.technicians.isNotEmpty ? widget.technicians : _defaultTechnicians,
    );
    if (_technician != null && !list.contains(_technician)) {
      list.add(_technician!);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    final laboratory = widget.laboratory;
    _nameController = TextEditingController(text: laboratory?.name ?? '');
    _locationController = TextEditingController(
      text: laboratory?.location ?? '',
    );
    _capacityController = TextEditingController(
      text: laboratory?.capacity ?? '',
    );
    _notesController = TextEditingController(text: laboratory?.notes ?? '');
    _technician = laboratory?.technician;
    _availability = laboratory?.availability ?? LabAvailability.activo;

    if (laboratory != null &&
        laboratory.latitude != null &&
        laboratory.longitude != null) {
      _pickedLatLng = LatLng(laboratory.latitude!, laboratory.longitude!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await showLocationPickerModal(
      context,
      initialSelection: _pickedLatLng,
    );
    if (result != null && mounted) {
      setState(() {
        _pickedLatLng = result;
        _locationController.text =
            'Campus ESPOCH (Lat: ${result.latitude.toStringAsFixed(4)}, Lng: ${result.longitude.toStringAsFixed(4)})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.laboratory != null;
    final techOptions = _technicianList;
    if (_technician == null && techOptions.isNotEmpty) {
      _technician = techOptions.first;
    }

    return AlertDialog(
      title: Text(
        isEditing ? 'Modificar Laboratorio' : 'Registrar Laboratorio',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('lab-name-field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Laboratorio',
                    hintText: 'Lab. Inteligencia Artificial y Robótica',
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                  validator: _requiredField(
                    'Ingresa el nombre del laboratorio',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('lab-location-field'),
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Ubicación Física',
                    hintText: 'Edificio o selección en mapa',
                    helperText: _pickedLatLng != null
                        ? 'Coord OSM: ${_pickedLatLng!.latitude.toStringAsFixed(5)}, ${_pickedLatLng!.longitude.toStringAsFixed(5)}'
                        : 'Edificio y referencia o punto en OpenStreetMap',
                    prefixIcon: const Icon(Icons.place_outlined),
                    suffixIcon: IconButton(
                      key: const Key('open-osm-map-btn'),
                      icon: const Icon(
                        Icons.map_outlined,
                        color: AppColors.fieBlue,
                      ),
                      tooltip: 'Ubicar en OpenStreetMap',
                      onPressed: _openMapPicker,
                    ),
                  ),
                  validator: _requiredField('Ingresa la ubicación física'),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  key: const Key('pick-location-osm-button'),
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.pin_drop_outlined, size: 18),
                  label: Text(
                    _pickedLatLng != null
                        ? '📍 Cambiar ubicación en OpenStreetMap'
                        : '🗺️ Ubicar en OpenStreetMap',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.fieBlue,
                    side: const BorderSide(color: AppColors.fieBlue),
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('lab-capacity-field'),
                  controller: _capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacidad de Equipos',
                    hintText: '25 PCs, 2 servidores, 1 proyector',
                    helperText: 'Equipos y estaciones de trabajo',
                    prefixIcon: Icon(Icons.computer_outlined),
                  ),
                  validator: _requiredField(
                    'Ingresa la capacidad del laboratorio',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('lab-technician-field'),
                  initialValue: _technician,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Técnico Responsable',
                    helperText: 'Técnicos registrados en la base de datos',
                    prefixIcon: Icon(Icons.engineering_outlined),
                  ),
                  items: [
                    for (final technician in techOptions)
                      DropdownMenuItem(
                        value: technician,
                        child: Text(technician),
                      ),
                  ],
                  validator: (value) => value == null
                      ? 'Selecciona un técnico responsable'
                      : null,
                  onChanged: (value) => setState(() => _technician = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LabAvailability>(
                  key: const Key('lab-availability-field'),
                  initialValue: _availability,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado Inicial',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: [
                    for (final status in LabAvailability.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _availability = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('lab-notes-field'),
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    helperText: 'Descripción de infraestructura',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: _requiredField(
                    'Añade observaciones de infraestructura',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('save-laboratory'),
          onPressed: _save,
          child: Text(isEditing ? 'Guardar cambios' : 'Registrar'),
        ),
      ],
    );
  }

  FormFieldValidator<String> _requiredField(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final id =
        widget.laboratory?.id ?? 'LAB-${DateTime.now().microsecondsSinceEpoch}';
    final techOptions = _technicianList;
    final chosenTech =
        _technician ??
        (techOptions.isNotEmpty ? techOptions.first : 'Carlos Mena');

    Navigator.pop(
      context,
      LabRecord(
        id: id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        capacity: _capacityController.text.trim(),
        technician: chosenTech,
        availability: _availability,
        notes: _notesController.text.trim(),
        latitude: _pickedLatLng?.latitude,
        longitude: _pickedLatLng?.longitude,
      ),
    );
  }
}

class _LabAvailabilityBadge extends StatelessWidget {
  const _LabAvailabilityBadge({required this.availability});

  final LabAvailability availability;

  @override
  Widget build(BuildContext context) {
    final color = switch (availability) {
      LabAvailability.activo => AppColors.green,
      LabAvailability.mantenimiento => AppColors.yellow,
      LabAvailability.inactivo => AppColors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        availability.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddScheduleDialog extends StatefulWidget {
  const _AddScheduleDialog({required this.laboratory});

  final String laboratory;

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  static const List<String> _timeSlots = [
    '07:00 - 09:00',
    '09:00 - 11:00',
    '11:00 - 13:00',
    '15:00 - 17:00',
    '17:00 - 19:00',
    '19:00 - 21:00',
  ];

  String _time = '07:00 - 09:00';
  final _courseController = TextEditingController();
  final _teacherController = TextEditingController();
  String _day = 'Lunes';

  @override
  void dispose() {
    _courseController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Añadir bloque · ${widget.laboratory}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _day,
              decoration: const InputDecoration(labelText: 'Día'),
              items: [
                for (final value in [
                  'Lunes',
                  'Martes',
                  'Miércoles',
                  'Jueves',
                  'Viernes',
                ])
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _day = value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const Key('schedule-time-field'),
              initialValue: _time,
              decoration: const InputDecoration(
                labelText: 'Bloque horario',
              ),
              items: [
                for (final slot in _timeSlots)
                  DropdownMenuItem(value: slot, child: Text(slot)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _time = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('schedule-course-field'),
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Materia'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('schedule-teacher-field'),
              controller: _teacherController,
              decoration: const InputDecoration(labelText: 'Docente'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _addBlock, child: const Text('Añadir')),
      ],
    );
  }

  void _addBlock() {
    final time = _time.trim();
    final course = _courseController.text.trim();
    final teacher = _teacherController.text.trim();
    if (time.isEmpty || course.isEmpty || teacher.isEmpty) return;
    Navigator.pop(context, _ScheduleBlock(_day, time, course, teacher));
  }
}

class _LiveMetrics {
  const _LiveMetrics({
    required this.incidentsCount,
    required this.resolutionTime,
    required this.worstLab,
    required this.availability,
    required this.hardwarePct,
    required this.softwarePct,
    required this.networkPct,
    required this.infraPct,
    required this.totalInPeriod,
  });

  final String incidentsCount;
  final String resolutionTime;
  final String worstLab;
  final String availability;
  final int hardwarePct;
  final int softwarePct;
  final int networkPct;
  final int infraPct;
  final int totalInPeriod;
}

class _PeriodMetrics {
  const _PeriodMetrics({
    required this.incidents,
    required this.resolution,
    required this.availability,
    required this.failures,
  });

  final String incidents;
  final String resolution;
  final String availability;
  final List<int> failures;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 126,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 19),
              const Spacer(),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: value.length > 12 ? 14 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureBar extends StatelessWidget {
  const _FailureBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final int percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 7,
              color: color,
              backgroundColor: AppColors.line,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabStatusRow extends StatelessWidget {
  const _LabStatusRow({
    required this.name,
    required this.status,
    required this.color,
    this.showDivider = false,
  });

  final String name;
  final String status;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 14, endIndent: 14),
      ],
    );
  }
}

class _ScheduleBlock {
  const _ScheduleBlock(this.day, this.time, this.course, this.teacher);

  final String day;
  final String time;
  final String course;
  final String teacher;
}

class _TechnicianStats {
  const _TechnicianStats({
    required this.attended,
    required this.resolved,
    required this.pending,
    required this.responseTime,
    required this.resolutionTime,
    required this.rating,
  });

  final int attended;
  final int resolved;
  final int pending;
  final String responseTime;
  final String resolutionTime;
  final String rating;
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, color: AppColors.muted, size: 30),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InfoMetricRow extends StatelessWidget {
  const _InfoMetricRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.fieBlue),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
