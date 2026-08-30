import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/license_category.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/balotario_repository.dart';
import '../datasources/balotario_local_data_source.dart';

final class BalotarioRepositoryImpl implements BalotarioRepository {
  const BalotarioRepositoryImpl(this._local);

  final BalotarioLocalDataSource _local;

  @override
  Future<Either<Failure, List<LicenseCategory>>> obtenerCategorias() =>
      _guardar(() => _local.categorias());

  @override
  Future<Either<Failure, LicenseCategory>> obtenerCategoria(String codigo) => _guardar(() async {
        final categorias = await _local.categorias();
        final encontrada = categorias.where((c) => c.codigo == codigo).firstOrNull;
        if (encontrada == null) throw CacheException('Categoria $codigo no existe');
        return encontrada;
      });

  @override
  Future<Either<Failure, List<Question>>> obtenerBalotario(String categoriaCodigo) =>
      _guardar(() => _local.balotario(categoriaCodigo));

  @override
  Future<Either<Failure, List<Question>>> obtenerPreguntasDeSimulacro({
    required String categoriaCodigo,
    required int cantidad,
    List<String> excluirIds = const [],
  }) =>
      _guardar(
        () => _local.muestraEstratificada(
          categoriaCodigo: categoriaCodigo,
          cantidad: cantidad,
          excluirIds: excluirIds,
        ),
      );

  Future<Either<Failure, T>> _guardar<T>(Future<T> Function() accion) async {
    try {
      return Right(await accion());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.mensaje));
    } catch (e) {
      return Left(ServerFailure('$e'));
    }
  }
}
