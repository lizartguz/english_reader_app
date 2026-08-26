import 'package:flutter/widgets.dart';

/// Identificadores estables para pruebas de widgets y flujos automatizados.
class AppKeys {
  const AppKeys._();

  static const loginEmailField = ValueKey<String>('login.email.field');
  static const loginPasswordField = ValueKey<String>('login.password.field');
  static const loginTogglePassword = ValueKey<String>('login.password.toggle');
  static const loginSubmitButton = ValueKey<String>('login.submit.button');

  static const storiesList = ValueKey<String>('stories.list');
  static const readerContent = ValueKey<String>('reader.content');
  static const readerScroll = ValueKey<String>('reader.scroll');
  static const readerSettingsButton = ValueKey<String>(
    'reader.settings.button',
  );
  static const readerSettingsSheet = ValueKey<String>('reader.settings.sheet');
  static const readerFontScaleSlider = ValueKey<String>(
    'reader.settings.font_scale.slider',
  );
  static const readerLineHeightSlider = ValueKey<String>(
    'reader.settings.line_height.slider',
  );
  static const readerSettingsReset = ValueKey<String>('reader.settings.reset');
  static const wordPronunciationButton = ValueKey<String>(
    'word.pronunciation.button',
  );
  static const vocabularyList = ValueKey<String>('vocabulary.list');
  static const vocabularyNotesField = ValueKey<String>(
    'vocabulary.notes.field',
  );
  static const vocabularyNotesSave = ValueKey<String>('vocabulary.notes.save');

  /// Identifica una tarjeta concreta de historia.
  static ValueKey<String> storyCard(String id) {
    return ValueKey<String>('stories.card.$id');
  }

  /// Identifica una palabra tocable dentro del lector.
  static ValueKey<String> readerWordToken(String word, int index) {
    return ValueKey<String>('reader.word.$word.$index');
  }

  /// Identifica una fila concreta del vocabulario personal.
  static ValueKey<String> vocabularyTile(String id) {
    return ValueKey<String>('vocabulary.tile.$id');
  }

  /// Identifica el menú de acciones de una palabra guardada.
  static ValueKey<String> vocabularyActions(String id) {
    return ValueKey<String>('vocabulary.actions.$id');
  }
}
