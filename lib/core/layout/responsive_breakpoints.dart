import 'package:flutter/material.dart';

/// Breakpoints compartidos para adaptar pantallas en móvil, tablet y Web.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double compact = 600;
  static const double medium = 900;
  static const double wide = 1200;

  /// Indica si el ancho debe tratarse como experiencia móvil.
  static bool isCompact(double width) => width < compact;

  /// Indica si el ancho permite composiciones de varias columnas.
  static bool isWide(double width) => width >= medium;

  /// Define padding lateral cómodo sin desperdiciar espacio en pantallas grandes.
  static EdgeInsets pagePadding(double width) {
    final horizontal = width >= wide
        ? 32.0
        : width >= compact
        ? 24.0
        : 16.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24);
  }
}

/// Centra contenido operativo y conserva ancho legible en Web.
class ResponsiveContentWidth extends StatelessWidget {
  const ResponsiveContentWidth({
    required this.child,
    this.maxWidth = 820,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  /// Aplica una restricción horizontal sin afectar el alto disponible.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
