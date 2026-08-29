import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_info.dart';
import '../bloc/auth_bloc.dart';

/// Pantalla de autenticación del usuario cliente.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Vaciar antes de liberar suelta la referencia a la contraseña en cuanto
    // se abandona la pantalla, sin esperar a que el recolector pase.
    _passwordController.clear();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.message != current.message || previous.status != current.status,
      listener: (context, state) {
        // Con la sesión ya iniciada la contraseña no vuelve a hacer falta: se
        // vacía sin esperar a que el router desmonte esta pantalla.
        if (state.status == AuthStatus.authenticated) _passwordController.clear();

        final message = state.message;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        AppInfo.logoAsset,
                        height: 72,
                        semanticLabel: '${AppInfo.displayName} logo',
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppInfo.displayName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión para continuar leyendo.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        key: AppKeys.loginEmailField,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu correo electrónico.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: AppKeys.loginPasswordField,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            key: AppKeys.loginTogglePassword,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return FilledButton.icon(
                            key: AppKeys.loginSubmitButton,
                            onPressed: state.isLoading ? null : _submit,
                            icon: state.isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: const Text('Iniciar sesión'),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.forgotPassword),
                        child: const Text('Olvidé mi contraseña'),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: const Text('Crear cuenta nueva'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Envía credenciales al BLoC sin exponer tokens en la UI.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}
