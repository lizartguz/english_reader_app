class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const home = '/stories';
  static const stories = '/stories';
  static const reader = '/reader/:storyId';
  static const vocabulary = '/vocabulary';
  static const profile = '/profile';

  static String readerPath(String storyId) => '/reader/$storyId';
}
