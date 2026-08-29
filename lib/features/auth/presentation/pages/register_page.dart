import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/app_routes.dart';
import '../cubit/account_cubit.dart';
import '../widgets/auth_form_scaffold.dart';

/// Pantalla de registro de nuevos usuarios cliente.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Vaciar antes de liberar suelta la referencia a la contraseña en cuanto
    // se abandona la pantalla, sin esperar a que el recolector pase.
    _passwordController.clear();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Construye el formulario con la política de contraseña de la API.
  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Crear cuenta',
      subtitle:
          'Regístrate para leer y guardar tu vocabulario en '
          '${AppInfo.displayName}.',
      onSuccess: () {
        // La cuenta ya está creada: la contraseña no debe seguir en memoria
        // mientras se navega.
        _passwordController.clear();
        context.go(AppRoutes.login);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: AppKeys.registerFirstNameField,
              controller: _firstNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => _requiredName(value, 'tu nombre'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: AppKeys.registerLastNameField,
              controller: _lastNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) => _requiredName(value, 'tu apellido'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: AppKeys.registerEmailField,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: AppKeys.registerPhoneField,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: AppKeys.registerPasswordField,
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                helperText:
                    'Mínimo 8 caracteres con mayúscula, minúscula '
                    'y número.',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 24),
            BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                return FilledButton.icon(
                  key: AppKeys.registerSubmitButton,
                  onPressed: state.isSubmitting ? null : _submit,
                  icon: state.isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt),
                  label: const Text('Crear cuenta'),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  /// Envía el registro solo cuando el formulario local es válido.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AccountCubit>().register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
  }

  /// Valida nombres con el mismo mínimo que exige la API.
  String? _requiredName(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa $label.';
    if (text.length < 2) return 'Debe tener al menos 2 caracteres.';
    return null;
  }

  /// Evita enviar correos con formato inválido a la API.
  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'El correo electrónico no es válido.';
    }
    return null;
  }

  /// Refleja la política de contraseña definida por la API.
  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'Debe tener al menos 8 caracteres.';
    if (!RegExp(r'[a-z]').hasMatch(text)) return 'Incluye una minúscula.';
    if (!RegExp(r'[A-Z]').hasMatch(text)) return 'Incluye una mayúscula.';
    if (!RegExp(r'[0-9]').hasMatch(text)) return 'Incluye un número.';
    return null;
  }
}
