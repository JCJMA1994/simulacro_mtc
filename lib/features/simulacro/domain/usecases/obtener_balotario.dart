import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question.dart';
import '../repositories/balotario_repository.dart';

final class ObtenerBalotarioParams extends Equatable {
  const ObtenerBalotarioParams({required this.categoriaCodigo});

  final String categoriaCodigo;

  @override
  List<Object?> get props => [categoriaCodigo];
}

/// Recupera el banco completo de preguntas para estudio y repaso.
final class ObtenerBalotario implements UseCase<List<Question>, ObtenerBalotarioParams> {
  const ObtenerBalotario(this._repository);

  final BalotarioRepository _repository;

  @override
  Future<Either<Failure, List<Question>>> call(ObtenerBalotarioParams params) {
    return _repository.obtenerBalotario(params.categoriaCodigo);
  }
}
