import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/license_category.dart';
import '../entities/question.dart';

abstract interface class BalotarioRepository {
  Future<Either<Failure, List<LicenseCategory>>> obtenerCategorias();

  Future<Either<Failure, LicenseCategory>> obtenerCategoria(String codigo);

  /// Banco completo de la categoria (para modo estudio).
  Future<Either<Failure, List<Question>>> obtenerBalotario(String categoriaCodigo);

  /// Muestra aleatoria estratificada por topico para un simulacro.
  Future<Either<Failure, List<Question>>> obtenerPreguntasDeSimulacro({
    required String categoriaCodigo,
    required int cantidad,
    List<String> excluirIds = const [],
  });
}
