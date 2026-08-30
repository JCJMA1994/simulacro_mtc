import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/exam_session.dart';
import '../../domain/repositories/balotario_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_data_source.dart';

final class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._local, this._balotario);

  final SessionLocalDataSource _local;
  final BalotarioRepository _balotario;

  @override
  Future<Either<Failure, Unit>> guardarEnCurso(ExamSession sesion) async {
    try {
      await _local.guardar(sesion);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.mensaje));
    }
  }

  @override
  Future<Either<Failure, ExamSession?>> recuperarEnCurso() async {
    try {
      final sesion = await _local.recuperar((codigo) async {
        final resultado = await _balotario.obtenerCategoria(codigo);
        return resultado.fold(
          (falla) => throw CacheException(falla.mensaje),
          (categoria) => categoria,
        );
      });
      return Right(sesion);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.mensaje));
    }
  }

  @override
  Future<Either<Failure, Unit>> descartarEnCurso() async {
    try {
      await _local.descartar();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.mensaje));
    }
  }
}
