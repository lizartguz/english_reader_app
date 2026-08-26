import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/responsive_breakpoints.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Pantalla con datos básicos de sesión del cliente.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// Presenta el perfil con ancho legible en móvil, tablet y Web.
  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: ResponsiveBreakpoints.pagePadding(constraints.maxWidth),
              child: ResponsiveContentWidth(
                maxWidth: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(
                        (user?.fullName.isNotEmpty == true
                                ? user!.fullName
                                : user?.email ?? 'U')
                            .characters
                            .first
                            .toUpperCase(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName
                          : 'Usuario',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(user?.email ?? ''),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.read<AuthBloc>().add(
                        const AuthLogoutRequested(),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
