import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/app_routes.dart';
import '../cubit/account_cubit.dart';
import '../widgets/auth_form_scaffold.dart';

/// Pantalla para solicitar el correo de recuperación de contraseña.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Pide el correo y lleva al paso de token cuando la API responde.
  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Recuperar contraseña',
      subtitle:
          'Te enviaremos un enlace con un token para definir una '
          'contraseña nueva.',
      onSuccess: () => context.go(AppRoutes.resetPassword),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: AppKeys.forgotPasswordEmailField,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
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
            const SizedBox(height: 24),
            BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                return FilledButton.icon(
                  key: AppKeys.forgotPasswordSubmitButton,
                  onPressed: state.isSubmitting ? null : _submit,
                  icon: state.isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Enviar enlace'),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.resetPassword),
              child: const Text('Ya tengo un token'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  /// Envía la solicitud sin revelar si la cuenta existe.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AccountCubit>().requestPasswordReset(
      _emailController.text.trim(),
    );
  }
}
