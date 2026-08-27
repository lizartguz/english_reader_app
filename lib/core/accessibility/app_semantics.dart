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

  /// Describe el progreso visible del lector sin depender solo del indicador visual.
  static String readingProgress(double percent) {
    return 'Progreso de lectura ${percent.round()} por ciento';
  }

  /// Describe una palabra guardada dentro del vocabulario personal.
  static String vocabularyEntry({
    required String word,
    String? translation,
    required String status,
  }) {
    final translated = translation == null || translation.isEmpty
        ? ''
        : ', traducción $translation';
    return 'Palabra guardada $word$translated, estado $status';
  }

  /// Describe el menú contextual de una palabra guardada.
  static String vocabularyActions(String word) {
    return 'Acciones para $word';
  }

  /// Describe la acción principal de guardar una palabra.
  static String saveWord(String word) {
    return 'Guardar $word en vocabulario';
  }
}
