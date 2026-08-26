/// Textos semánticos centralizados para lectores de pantalla.
class AppSemantics {
  const AppSemantics._();

  /// Describe una palabra tocable del lector.
  static String readerWord(String word) {
    return 'Consultar palabra $word';
  }

  /// Describe una tarjeta de historia como acción navegable.
  static String storyCard({
    required String title,
    required String readingLevel,
    int? estimatedMinutes,
  }) {
    final minutes = estimatedMinutes == null
        ? ''
        : ', duración aproximada $estimatedMinutes minutos';
    return 'Abrir historia $title, nivel $readingLevel$minutes';
  }

  /// Describe el botón de pronunciación de una palabra.
  static String pronounceWord(String word) {
    return 'Pronunciar $word';
  }

  /// Describe el estado temporal mientras se reproduce audio.
  static String pronouncingWord(String word) {
    return 'Reproduciendo pronunciación de $word';
  }
}
