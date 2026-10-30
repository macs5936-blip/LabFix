import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/report_model.dart';
import '../../../widgets/app_drawer.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_settings_screen.dart';
import 'ai_assistant_screen.dart';
import 'diagnostic_chatbot_screen.dart';
import 'report_history_screen.dart';
import 'report_form_screen.dart';
import 'student_dashboard_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.onLogout,
    this.auth,
    this.firestore,
  });

  final ValueChanged<BuildContext> onLogout;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  late final List<IncidentReport> _reports = List.of(mockReports);

  void _addReport(IncidentReport report) {
    setState(() => _reports.insert(0, report));
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentDashboardScreen(
        reports: _reports,
        onReportCreated: _addReport,
        onOpenHistory: () => setState(() => _selectedIndex = 1),
        auth: widget.auth,
        firestore: widget.firestore,
      ),
      ReportHistoryScreen(
        reports: _reports,
        auth: widget.auth,
        firestore: widget.firestore,
      ),
      const AiAssistantScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Reportes FIE',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Abrir menú',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => _openNotifications(context),
            icon: const Icon(Icons.notifications_outlined),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.school_outlined, color: AppColors.gold),
          ),
        ],
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onSelectTab: _selectTab,
        onOpenNotifications: () => _openNotifications(context),
        onOpenProfile: () => _openProfile(context),
        onOpenSettings: () => _openProfileSettings(context),
        onOpenGuide: () => _openInfoPage(
          context,
          'Guía de Reporte de Labs',
          Icons.menu_book_outlined,
          const [
            'Selecciona el edificio y laboratorio donde ocurre la incidencia.',
            'Indica el número de máquina o puesto.',
            'Describe el problema y elige su nivel de urgencia.',
            'Envía el reporte para que soporte FIE pueda atenderlo.',
          ],
        ),
        onOpenSupport: () => _openInfoPage(
          context,
          'Soporte Técnico FIE',
          Icons.support_agent_outlined,
          const [
            'Contacta al equipo de soporte de laboratorios FIE.',
            'Correo: soporte.fie@espoch.edu.ec',
            'Incluye el laboratorio y número de puesto en tu consulta.',
          ],
        ),
        onOpenDiagnostic: _openDiagnosticChatbot,
        onLogout: () => _confirmLogout(context),
        auth: widget.auth,
        firestore: widget.firestore,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              key: const Key('open-diagnostic-chatbot'),
              tooltip: 'Asistente de Diagnóstico IA',
              onPressed: _openDiagnosticChatbot,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Diagnóstico IA'),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.fieBlueDark,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Asistente IA',
          ),
        ],
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          reports: _reports,
          auth: widget.auth,
          firestore: widget.firestore,
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          auth: widget.auth,
          firestore: widget.firestore,
        ),
      ),
    );
  }

  void _openProfileSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSettingsScreen(
          auth: widget.auth,
          firestore: widget.firestore,
        ),
      ),
    );
  }


  void _openInfoPage(
    BuildContext context,
    String title,
    IconData icon,
    List<String> details,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _DrawerInfoPage(title: title, icon: icon, details: details),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    Navigator.of(context).pop();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta estudiantil?'),
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
    if (shouldLogout != true || !mounted || !context.mounted) return;
    widget.onLogout(context);
  }

  void _openDiagnosticChatbot() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DiagnosticChatbotScreen(onCreateReport: _openReportForm),
      ),
    );
  }

  void _openReportForm(String category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewReportScreen(
          onSubmit: _addReport,
          initialCategory: category,
          onOpenHistory: () => setState(() => _selectedIndex = 1),
          auth: widget.auth,
          firestore: widget.firestore,
        ),
      ),
    );
  }
}

class _DrawerInfoPage extends StatelessWidget {
  const _DrawerInfoPage({
    required this.title,
    required this.icon,
    required this.details,
  });

  final String title;
  final IconData icon;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(icon, size: 42, color: AppColors.fieBlue),
          const SizedBox(height: 16),
          for (final detail in details)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
