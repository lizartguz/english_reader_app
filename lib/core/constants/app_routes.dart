class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/stories';
  static const stories = '/stories';
  static const reader = '/reader/:storyId';
  static const vocabulary = '/vocabulary';
  static const profile = '/profile';

  /// Ruta del lector para una historia.
  ///
  /// El identificador se codifica porque viaja como segmento de ruta: uno que
  /// contenga `/` o caracteres reservados no encajaria con `/reader/:storyId` y
  /// la navegacion fallaria. `go_router` lo decodifica al leer el parametro.
  static String readerPath(String storyId) =>
      '/reader/${Uri.encodeComponent(storyId)}';

  /// Rutas accesibles sin sesión iniciada.
  static const publicRoutes = <String>[
    login,
    register,
    forgotPassword,
    resetPassword,
  ];
}
