import 'package:english_reader_app/app/router/app_router.dart';
import 'package:english_reader_app/app/theme/app_theme.dart';
import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/core/constants/app_routes.dart';
import 'package:english_reader_app/core/storage/preferences_service.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_session.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_user.dart';
import 'package:english_reader_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:english_reader_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:english_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:english_reader_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:english_reader_app/features/reader/presentation/cubit/reader_settings_cubit.dart';
import 'package:english_reader_app/features/stories/domain/entities/story.dart';
import 'package:english_reader_app/features/stories/domain/repositories/stories_repository.dart';
import 'package:english_reader_app/features/vocabulary/domain/entities/vocabulary_entry.dart';
import 'package:english_reader_app/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('flujo principal: login, lectura, palabra y vocabulario', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await PreferencesService.create();
    final store = _SmokeStore();
    final authRepository = _FakeAuthRepository();
    final authBloc = AuthBloc(authRepository)..add(const AuthStarted());
    final router = AppRouter(authBloc: authBloc).router;
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: authRepository),
          Provider<StoriesRepository>.value(
            value: _FakeStoriesRepository(store),
          ),
          Provider<ReaderRepository>.value(value: _FakeReaderRepository(store)),
          Provider<VocabularyRepository>.value(
            value: _FakeVocabularyRepository(store),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authBloc),
            BlocProvider(
              create: (_) => ReaderSettingsCubit(preferences)..load(),
            ),
          ],
          child: _SmokeApp(router: router),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AppKeys.loginEmailField), _user.email);
    await tester.enterText(
      find.byKey(AppKeys.loginPasswordField),
      'Cliente123*',
    );
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.storiesList), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.storyCard(_story.id)));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.readerContent), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.readerWordToken('Hello', 0)));
    await tester.pumpAndSettle();

    expect(find.text('hola'), findsOneWidget);
    await tester.tap(find.text('Guardar palabra'));
    await tester.pumpAndSettle();

    expect(store.savedEntries, hasLength(1));

    Navigator.of(tester.element(find.text('hola').first)).pop();
    await tester.pumpAndSettle();

    router.go(AppRoutes.vocabulary);
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.vocabularyList), findsOneWidget);
    expect(find.byKey(AppKeys.vocabularyTile('saved-hello')), findsOneWidget);
  });
}

/// App mínima para ejecutar rutas reales dentro del smoke test.
class _SmokeApp extends StatelessWidget {
  const _SmokeApp({required this.router});

  final GoRouter router;

  /// Construye MaterialApp con el router real de Readeriz.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Estado compartido entre repositorios fake del flujo principal.
class _SmokeStore {
  final List<VocabularyEntry> savedEntries = [];
  ReadingProgress? progress;
}

/// Repositorio de autenticación fake para probar navegación protegida.
class _FakeAuthRepository implements AuthRepository {
  bool _hasSession = false;

  /// Simula login exitoso de cliente sin llamar al backend.
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    _hasSession = true;
    return AuthSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      tokenType: 'Bearer',
      expiresIn: 900,
      sessionExpiresAt: DateTime(2026, 12, 31),
      user: _user,
    );
  }

  /// Indica si existe una sesión local simulada.
  @override
  Future<bool> hasLocalSession() async => _hasSession;

  /// Limpia la sesión fake.
  @override
  Future<void> logout() async {
    _hasSession = false;
  }

  @override
  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async => 'Cuenta creada.';

  @override
  Future<String> requestPasswordReset(String email) async => 'Correo enviado.';

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async => 'Contrasena actualizada.';

  /// Devuelve el usuario cuando el test ya inició sesión.
  @override
  Future<AuthUser?> verifySession() async => _hasSession ? _user : null;
}

/// Repositorio fake de historias para cargar contenido estable.
class _FakeStoriesRepository implements StoriesRepository {
  const _FakeStoriesRepository(this._store);

  final _SmokeStore _store;

  /// Devuelve una lista con una historia publicada.
  @override
  Future<List<Story>> listStories() async => const [_story];

  /// Expone el avance guardado para pintar progreso en el listado.
  @override
  Future<List<ReadingProgress>> listReadingProgress() async {
    final progress = _store.progress;
    return progress == null ? const [] : [progress];
  }

  /// Devuelve la historia solicitada y registra que fue usada por el flujo.
  @override
  Future<Story> getStory(String id) async {
    _store.progress ??= const ReadingProgress(
      id: 'progress-1',
      userId: 'user-1',
      storyId: 'story-1',
      progressPercent: 0,
    );
    return _story;
  }
}

/// Repositorio fake del lector para lookup, vocabulario y progreso.
class _FakeReaderRepository implements ReaderRepository {
  const _FakeReaderRepository(this._store);

  final _SmokeStore _store;

  /// Devuelve la historia usada por el flujo principal.
  @override
  Future<Story> getStory(String storyId) async => _story;

  /// Devuelve progreso simulado para restauración.
  @override
  Future<ReadingProgress?> getProgress(String storyId) async => _store.progress;

  /// Devuelve una palabra con traducción y pronunciación localizable.
  @override
  Future<WordDetail> lookupWord(String word) async => _word;

  /// Guarda una palabra en el store compartido con vocabulario.
  @override
  Future<WordDetail> saveVocabulary({
    required String wordEntryId,
    required String storyId,
  }) async {
    if (_store.savedEntries.isEmpty) {
      _store.savedEntries.add(
        VocabularyEntry(
          id: 'saved-hello',
          status: 'saved',
          savedAt: DateTime(2026),
          storyTitle: _story.title,
          word: _word.copyWithSaved(),
        ),
      );
    }
    return _word.copyWithSaved();
  }

  /// Persiste progreso calculado por la UI.
  @override
  Future<ReadingProgress> saveProgress({
    required String storyId,
    required double progressPercent,
    String? lastPosition,
    bool? completed,
  }) async {
    final progress = ReadingProgress(
      id: 'progress-1',
      userId: 'user-1',
      storyId: storyId,
      progressPercent: progressPercent,
      lastPosition: lastPosition,
      completedAt: completed == true ? DateTime(2026) : null,
      lastReadAt: DateTime(2026),
    );
    _store.progress = progress;
    return progress;
  }
}

/// Repositorio fake para leer vocabulario guardado por el lector.
class _FakeVocabularyRepository implements VocabularyRepository {
  const _FakeVocabularyRepository(this._store);

  final _SmokeStore _store;

  /// Lista las palabras guardadas durante el smoke test.
  @override
  Future<List<VocabularyEntry>> listVocabulary() async {
    return List<VocabularyEntry>.from(_store.savedEntries);
  }

  /// Actualiza estado o notas conservando el registro existente.
  @override
  Future<VocabularyEntry> updateVocabulary({
    required String id,
    String? status,
    String? notes,
  }) async {
    final index = _store.savedEntries.indexWhere((entry) => entry.id == id);
    final current = _store.savedEntries[index];
    final updated = VocabularyEntry(
      id: current.id,
      status: status ?? current.status,
      notes: notes ?? current.notes,
      savedAt: current.savedAt,
      word: current.word,
      storyTitle: current.storyTitle,
    );
    _store.savedEntries[index] = updated;
    return updated;
  }

  /// Elimina una palabra del store compartido.
  @override
  Future<void> deleteVocabulary(String id) async {
    _store.savedEntries.removeWhere((entry) => entry.id == id);
  }
}

extension on WordDetail {
  /// Marca la palabra como guardada para simular la respuesta de la API.
  WordDetail copyWithSaved() {
    return WordDetail(
      id: id,
      word: word,
      normalizedWord: normalizedWord,
      language: language,
      phonetic: phonetic,
      definitionEn: definitionEn,
      partOfSpeech: partOfSpeech,
      translations: translations,
      examples: examples,
      pronunciations: pronunciations,
      isSaved: true,
      savedWordId: 'saved-hello',
    );
  }
}

const _user = AuthUser(
  id: 'user-1',
  email: 'cliente.flutter.test@englishreader.local',
  firstName: 'Cliente',
  lastName: 'Flutter',
  fullName: 'Cliente Flutter',
  status: 'active',
  roles: ['CLIENT'],
  permissions: [],
);

const _story = Story(
  id: 'story-1',
  title: 'Hello Reader',
  slug: 'hello-reader',
  status: 'published',
  sortOrder: 1,
  readingLevel: StoryReadingLevel(
    id: 'level-1',
    code: 'A1',
    name: 'Principiante',
  ),
  genres: [StoryGenre(id: 'genre-1', code: 'daily', name: 'Daily life')],
  assets: [],
  summary: 'A short story for the smoke flow.',
  content: 'Hello reader.\n\nPractice every day.',
  estimatedReadingMinutes: 3,
);

const _word = WordDetail(
  id: 'word-hello',
  word: 'Hello',
  normalizedWord: 'hello',
  language: 'en',
  phonetic: '/həˈloʊ/',
  definitionEn: 'Used as a greeting.',
  partOfSpeech: 'interjection',
  translations: [
    WordTranslation(
      id: 'translation-1',
      targetLanguage: 'es',
      translation: 'hola',
    ),
  ],
  examples: [
    WordExample(id: 'example-1', exampleText: 'Hello, reader!', sortOrder: 1),
  ],
  pronunciations: [],
  isSaved: false,
);
