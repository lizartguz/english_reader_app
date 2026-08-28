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

  static String readerPath(String storyId) => '/reader/$storyId';

  /// Rutas accesibles sin sesión iniciada.
  static const publicRoutes = <String>[
    login,
    register,
    forgotPassword,
    resetPassword,
  ];
}
