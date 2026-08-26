import 'package:flutter/material.dart';

import '../../../../core/widgets/app_loading_view.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppLoadingView(message: 'Verificando sesión...'),
    );
  }
}
