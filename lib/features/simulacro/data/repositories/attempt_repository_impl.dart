import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/repositories/attempt_repository.dart';
import '../datasources/attempt_local_data_source.dart';

final class AttemptRepositoryImpl implements AttemptRepository {
  const AttemptRepositoryImpl(this._local);

  final AttemptLocalDataSource _local;

  @override
  Future<Either<Failure, Unit>> guardar(ExamResult resultado) async {
    try {
      await _local.guardar(resultado);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.mensaje));
    }
  }

  @override
  Future<Either<Failure, List<ExamResult>>> historial(String categoriaCodigo) async {
    try {
      return Right(await _local.historial(categoriaCodigo));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.mensaje));
    }
  }

  @override
  Future<Either<Failure, List<String>>> preguntasFalladas(String categoriaCodigo) async {
    try {
      final intentos = await _local.historial(categoriaCodigo);
      final ids = <String>{for (final i in intentos) ...i.preguntasFalladasIds};
      return Right(ids.toList(growable: false));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.mensaje));
    }
  }

  @override
  Stream<List<ExamResult>> observarHistorial(String categoriaCodigo) =>
      _local.observar(categoriaCodigo);
}
