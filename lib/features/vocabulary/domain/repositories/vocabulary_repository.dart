import '../entities/vocabulary_entry.dart';

/// Contrato del vocabulario personal consumido por la app móvil.
abstract class VocabularyRepository {
  /// Lista las palabras guardadas por el usuario autenticado.
  Future<List<VocabularyEntry>> listVocabulary();

  /// Actualiza estado o notas de una palabra guardada.
  Future<VocabularyEntry> updateVocabulary({
    required String id,
    String? status,
    String? notes,
  });

  /// Elimina una palabra del vocabulario personal.
  Future<void> deleteVocabulary(String id);
}
