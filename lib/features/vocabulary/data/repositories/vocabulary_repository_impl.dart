import '../../../../core/network/api_client.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../datasources/vocabulary_remote_datasource.dart';

/// Implementación que traduce errores de API a mensajes amigables.
class VocabularyRepositoryImpl implements VocabularyRepository {
  const VocabularyRepositoryImpl({
    required VocabularyRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final VocabularyRemoteDataSource _remoteDataSource;

  /// Obtiene las palabras guardadas del usuario actual.
  @override
  Future<List<VocabularyEntry>> listVocabulary() async {
    try {
      return _remoteDataSource.listVocabulary();
    } catch (error) {
      throw mapDioException(error, 'No se pudo cargar el vocabulario.');
    }
  }

  /// Actualiza estado o nota de estudio de una palabra guardada.
  @override
  Future<VocabularyEntry> updateVocabulary({
    required String id,
    String? status,
    String? notes,
  }) async {
    try {
      return _remoteDataSource.updateVocabulary(
        id: id,
        status: status,
        notes: notes,
      );
    } catch (error) {
      throw mapDioException(error, 'No se pudo actualizar la palabra.');
    }
  }

  /// Quita la palabra del vocabulario personal.
  @override
  Future<void> deleteVocabulary(String id) async {
    try {
      await _remoteDataSource.deleteVocabulary(id);
    } catch (error) {
      throw mapDioException(error, 'No se pudo eliminar la palabra.');
    }
  }
}
