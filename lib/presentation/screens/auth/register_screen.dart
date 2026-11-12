import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_theme.dart';
import '../../../services/auth_service.dart';

/// Carreras disponibles en la Facultad de Informática y Electrónica de ESPOCH.
const _kCarreras = [
  'Tecnologías de la Información',
  'Software',
  'Telecomunicaciones',
  'Automatización',
  'Electrónica y Automatización Industrial',
  'Electrónica y Telecomunicaciones',
];

/// Periodos académicos (PAO).
const _kPaos = [
  'PAO 1',
  'PAO 2',
  'PAO 3',
  'PAO 4',
  'PAO 5',
  'PAO 6',
  'PAO 7',
  'PAO 8',
  'PAO 9',
  'PAO 10',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthService _authService =
      widget.authService ?? AuthService();

  final _formKey = GlobalKey<FormState>();

  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  String? _carrera;
  String? _pao;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Validation helpers ───────────────────────────────────────────────────

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo "$label" es obligatorio.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio.';
    }
    final emailRegex = RegExp(r'^[\w\-.+]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de teléfono es obligatorio.';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Ingresa un número válido (7–15 dígitos).';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 6) return 'Mínimo 6 caracteres.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_carrera == null) {
      _showSnack('Selecciona una carrera.', isError: true);
      return;
    }
    if (_pao == null) {
      _showSnack('Selecciona un PAO / Semestre.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerStudent(
        nombres: _nombresCtrl.text,
        apellidos: _apellidosCtrl.text,
        telefono: _telefonoCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        carrera: _carrera!,
        pao: _pao!,
      );

      // Cierra sesión temporalmente para exigir verificación antes del acceso
      await _authService.signOut();

      if (!mounted) return;
      _showSnack(
        '¡Cuenta creada! Revisa tu correo institucional para verificar tu cuenta antes de ingresar.',
        isError: false,
      );
      // Return to login after a short delay so the SnackBar is visible.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showSnack(_firebaseError(e), isError: true);
    } on Exception catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _firebaseError(FirebaseAuthException e) => switch (e.code) {
    'email-already-in-use' =>
      'Este correo ya está registrado. Inicia sesión o usa otro correo.',
    'invalid-email' => 'El correo no tiene un formato válido.',
    'weak-password' => 'La contraseña es demasiado débil (mínimo 6 caracteres).',
    'operation-not-allowed' =>
      'El registro con correo no está habilitado. Contacta al administrador.',
    'network-request-failed' =>
      'Sin conexión. Revisa tu acceso a internet.',
    _ => e.message ?? 'No se pudo crear la cuenta. Inténtalo de nuevo.',
  };

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    _FieHeader(
                      title: 'Crear cuenta',
                      subtitle:
                          'Completa tus datos para acceder al sistema de soporte.',
                    ),

                    const SizedBox(height: 25),
                    Text(
                      'Datos personales',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Nombres
                    TextFormField(
                      key: const Key('register-nombres'),
                      controller: _nombresCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombres completos',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => _required(v, 'Nombres'),
                    ),
                    const SizedBox(height: 13),

                    // Apellidos
                    TextFormField(
                      key: const Key('register-apellidos'),
                      controller: _apellidosCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos completos',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => _required(v, 'Apellidos'),
                    ),
                    const SizedBox(height: 13),

                    // Teléfono
                    TextFormField(
                      key: const Key('register-telefono'),
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\+\-\(\)]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Número de teléfono (Celular)',
                        hintText: '+593 98 765 4321',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: _validateTelefono,
                    ),
                    const SizedBox(height: 22),

                    Text(
                      'Datos académicos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Carrera
                    DropdownButtonFormField<String>(
                      key: const Key('register-carrera'),
                      initialValue: _carrera,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Carrera',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: _kCarreras
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _carrera = v),
                      validator: (_) =>
                          _carrera == null ? 'Selecciona una carrera.' : null,
                    ),
                    const SizedBox(height: 13),

                    // PAO / Semestre
                    DropdownButtonFormField<String>(
                      key: const Key('register-pao'),
                      initialValue: _pao,
                      decoration: const InputDecoration(
                        labelText: 'PAO / Semestre',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      items: _kPaos
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _pao = v),
                      validator: (_) =>
                          _pao == null ? 'Selecciona un PAO.' : null,
                    ),
                    const SizedBox(height: 22),

                    Text(
                      'Acceso a la cuenta',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Correo
                    TextFormField(
                      key: const Key('register-email'),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'nombre@espoch.edu.ec o personal@gmail.com',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 13),

                    // Contraseña
                    TextFormField(
                      key: const Key('register-password'),
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 13),

                    // Confirmar contraseña
                    TextFormField(
                      key: const Key('register-confirm-password'),
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirm
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validateConfirm,
                    ),

                    // Rol informativo
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fieBlue.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.fieBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.fieBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tu cuenta será registrada con el rol de Estudiante. '
                              'Un administrador puede actualizar tu rol si es necesario.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.fieBlue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Botón Crear Cuenta
                    FilledButton.icon(
                      key: const Key('register-submit'),
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_outlined),
                      label: const Text('Crear Cuenta'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.fieBlue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Volver al login
                    Center(
                      child: TextButton.icon(
                        key: const Key('register-back-to-login'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('¿Ya tienes cuenta? Inicia sesión'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.fieBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared FIE header widget ─────────────────────────────────────────────────

class _FieHeader extends StatelessWidget {
  const _FieHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.fieBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.fieBlue,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESPOCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Facultad de Informática y Electrónica',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

