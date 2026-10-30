import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/lab_model.dart';
import '../../../data/report_model.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.onLogout});

  final ValueChanged<BuildContext> onLogout;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _period = 'Este Mes';
  String _userSearch = '';
  String _selectedLab = 'Lab. Redes y Telecomunicaciones';
  String _selectedTechnician = 'Carlos Mena';

  final List<_ManagedUser> _users = [
    _ManagedUser(
      name: 'Ana Paredes',
      email: 'ana.paredes@espoch.edu.ec',
      code: 'EST-FIE-2024-018',
      role: 'Estudiante',
    ),
    _ManagedUser(
      name: 'Luis Cárdenas',
      email: 'luis.cardenas@espoch.edu.ec',
      code: 'EST-FIE-2023-076',
      role: 'Estudiante',
    ),
    _ManagedUser(
      name: 'Carlos Mena',
      email: 'carlos.mena@espoch.edu.ec',
      code: 'TEC-FIE-014',
      role: 'Técnico',
    ),
    _ManagedUser(
      name: 'Sofía Viteri',
      email: 'sofia.viteri@espoch.edu.ec',
      code: 'TEC-FIE-022',
      role: 'Técnico',
    ),
    _ManagedUser(
      name: 'David León',
      email: 'david.leon@espoch.edu.ec',
      code: 'TEC-FIE-031',
      role: 'Técnico',
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

  static const _periodMetrics = {
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

  _PeriodMetrics get _metrics => _periodMetrics[_period]!;

  _TechnicianStats get _technicianStats =>
      _technicianStatsMap[_selectedTechnician]!;

  Map<String, _TechnicianStats> get _technicianStatsMap =>
      _technicianStatsByName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showExportDialog() async {
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
          'El informe general de $_period está listo para descargar en PDF / Excel. (Descarga simulada)',
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

  Widget _buildUsersTab() {
    final query = _userSearch.trim().toLowerCase();
    final visibleUsers = _users.where((user) {
      return query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.code.toLowerCase().contains(query);
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
          const _AdminEmptyState(
            icon: Icons.person_search_outlined,
            message: 'No se encontraron usuarios.',
          )
        else
          for (final user in visibleUsers) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.fieBlue.withValues(alpha: 0.1),
                      foregroundColor: AppColors.fieBlue,
                      child: Text(_initials(user.name)),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.code,
                            style: const TextStyle(
                              color: AppColors.fieBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 122,
                      child: DropdownButtonFormField<String>(
                        key: Key('role-${user.code}'),
                        initialValue: user.role,
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
                        ],
                        onChanged: (role) {
                          if (role == null || role == user.role) return;
                          setState(() => user.role = role);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Rol de ${user.name} actualizado a $role',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
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
          label: const Text('Registrar / Modificar Laboratorios'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.fieBlue,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<List<LabRecord>>(
          valueListenable: LabCatalog.labs,
          builder: (context, laboratories, _) =>
              DropdownButtonFormField<String>(
                key: const Key('schedule-lab-selector'),
                initialValue: _selectedLab,
                isExpanded: true,
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
              ),
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
                    IconButton(
                      key: Key('edit-lab-${laboratory.id}'),
                      tooltip: 'Editar ${laboratory.name}',
                      onPressed: () => _openLaboratoryEditor(laboratory),
                      icon: const Icon(Icons.edit_outlined),
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

  Future<void> _openLaboratoryEditor([LabRecord? existing]) async {
    final saved = await showDialog<LabRecord>(
      context: context,
      builder: (_) => _LabEditorDialog(laboratory: existing),
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
          ListView(
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
                      'Indicadores globales de laboratorios y soporte',
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
                  const Icon(Icons.insights_outlined, color: AppColors.fieBlue),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 4,
                children: [
                  for (final period in _periodMetrics.keys)
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
                          value: _metrics.incidents,
                          icon: Icons.report_outlined,
                          color: AppColors.fieBlue,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _MetricCard(
                          label: 'Tiempo promedio de resolución',
                          value: _metrics.resolution,
                          icon: Icons.schedule_outlined,
                          color: AppColors.yellow,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const _MetricCard(
                          label: 'Laboratorio con mayor tasa de fallos',
                          value: 'Redes y Telecomunicaciones',
                          icon: Icons.warning_amber_outlined,
                          color: AppColors.red,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _MetricCard(
                          label: 'Disponibilidad de equipos',
                          value: _metrics.availability,
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
                  child: Column(
                    children: [
                      _FailureBar(
                        label: 'Hardware',
                        percentage: _metrics.failures[0],
                        color: AppColors.fieBlue,
                      ),
                      _FailureBar(
                        label: 'Software',
                        percentage: _metrics.failures[1],
                        color: AppColors.green,
                      ),
                      _FailureBar(
                        label: 'Red',
                        percentage: _metrics.failures[2],
                        color: AppColors.yellow,
                      ),
                      _FailureBar(
                        label: 'Infraestructura',
                        percentage: _metrics.failures[3],
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
                  Text('3 sedes', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 9),
              ValueListenableBuilder<List<LabRecord>>(
                valueListenable: LabCatalog.labs,
                builder: (context, laboratories, _) => Card(
                  child: Column(
                    children: [
                      for (var index = 0; index < laboratories.length; index++)
                        _LabStatusRow(
                          name: laboratories[index].name,
                          status: laboratories[index].availability.label,
                          color: _availabilityColor(
                            laboratories[index].availability,
                          ),
                          showDivider: index < laboratories.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('export-report'),
                onPressed: _showExportDialog,
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
                label: const Text('Registrar / Modificar Laboratorios'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.fieBlue,
                  side: const BorderSide(color: AppColors.fieBlue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
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
  const _LabEditorDialog({this.laboratory});

  final LabRecord? laboratory;

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

  static const _technicians = ['Carlos Mena', 'Sofía Viteri', 'David León'];

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.laboratory != null;
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
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('lab-location-field'),
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación Física',
                    hintText: 'Edificio FIE - Planta Alta, Aula 204',
                    helperText: 'Edificio y referencia del espacio',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: _requiredField('Ingresa la ubicación'),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('lab-technician-field'),
                  initialValue: _technician,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Técnico Responsable',
                    helperText: 'Encargado del laboratorio',
                  ),
                  items: [
                    for (final technician in _technicians)
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
                const SizedBox(height: 10),
                DropdownButtonFormField<LabAvailability>(
                  key: const Key('lab-availability-field'),
                  initialValue: _availability,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado Inicial',
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
                const SizedBox(height: 10),
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
    Navigator.pop(
      context,
      LabRecord(
        id: id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        capacity: _capacityController.text.trim(),
        technician: _technician!,
        availability: _availability,
        notes: _notesController.text.trim(),
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
  final _timeController = TextEditingController();
  final _courseController = TextEditingController();
  final _teacherController = TextEditingController();
  String _day = 'Lunes';

  @override
  void dispose() {
    _timeController.dispose();
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
            TextField(
              key: const Key('schedule-time-field'),
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Bloque horario',
                hintText: '08:00 - 10:00',
              ),
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
    final time = _timeController.text.trim();
    final course = _courseController.text.trim();
    final teacher = _teacherController.text.trim();
    if (time.isEmpty || course.isEmpty || teacher.isEmpty) return;
    Navigator.pop(context, _ScheduleBlock(_day, time, course, teacher));
  }
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

class _ManagedUser {
  _ManagedUser({
    required this.name,
    required this.email,
    required this.code,
    required this.role,
  });

  final String name;
  final String email;
  final String code;
  String role;
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
