import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/security/browser_url_sanitizer.dart';
import '../cubit/account_cubit.dart';
import '../widgets/auth_form_scaffold.dart';

/// Pantalla para definir una contraseña nueva con el token del correo.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({this.initialToken, this.cleanLocation, super.key});

  final String? initialToken;
  final String? cleanLocation;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final String _initialToken = _resolveInitialToken();
  late final TextEditingController _tokenController = TextEditingController(
    text: _initialToken,
  );
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _hideUrlTokenAfterRender();
  }

  @override
  void dispose() {
    // El token de recuperación es tan sensible como la contraseña: ambos se
    // vacían antes de liberar, sin esperar a que el recolector pase.
    _tokenController.clear();
    _passwordController.clear();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Borra el token de la URL Web sin quitarlo del formulario ya inicializado.
  void _hideUrlTokenAfterRender() {
    if (_initialToken.trim().isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeSensitiveQueryParameterFromBrowserUrl('token');
      final cleanLocation = widget.cleanLocation;
      if (!mounted || cleanLocation == null) return;

      context.replace(cleanLocation, extra: _initialToken);
    });
  }

  /// Resuelve el token desde el router o desde la URL Web con hash route.
  String _resolveInitialToken() {
    final routeToken = widget.initialToken?.trim();
    if (routeToken != null && routeToken.isNotEmpty) return routeToken;

    return readSensitiveQueryParameterFromBrowserUrl('token')?.trim() ?? '';
  }

  /// Acepta el token suelto o el enlace completo recibido por correo.
  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Nueva contraseña',
      subtitle: 'Pega el token del correo y define tu contraseña nueva.',
      onSuccess: () {
        // La contraseña ya se cambió y el token quedó consumido: ninguno de los
        // dos debe seguir en memoria mientras se navega al login.
        _passwordController.clear();
        _tokenController.clear();
        context.go(AppRoutes.login);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: AppKeys.resetPasswordTokenField,
              controller: _tokenController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Token o enlace del correo',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              validator: (value) {
                if (_extractToken(value ?? '').isEmpty) {
                  return 'Ingresa el token que recibiste por correo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: AppKeys.resetPasswordField,
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Contraseña nueva',
                helperText:
                    'Mínimo 8 caracteres con mayúscula, minúscula '
                    'y número.',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.lock_reset),
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
                  key: AppKeys.resetPasswordSubmitButton,
                  onPressed: state.isSubmitting ? null : _submit,
                  icon: state.isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Guardar contraseña'),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  /// Envía el token limpio para que la API valide la recuperación.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AccountCubit>().resetPassword(
      token: _extractToken(_tokenController.text),
      password: _passwordController.text,
    );
  }

  /// Extrae el token cuando el usuario pega el enlace completo del correo.
  String _extractToken(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';

    final uri = Uri.tryParse(text);
    final fromQuery = uri?.queryParameters['token'];
    return (fromQuery == null || fromQuery.isEmpty) ? text : fromQuery;
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
