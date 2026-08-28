import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';

/// Pantalla de arranque con la marca mientras se resuelve la sesión.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  /// Muestra el logo y un indicador mientras se verifica la sesión guardada.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppInfo.logoAsset,
                  height: 88,
                  semanticLabel: '${AppInfo.displayName} logo',
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  AppInfo.displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  AppInfo.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                const SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: const Text('Verificando sesión...'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
