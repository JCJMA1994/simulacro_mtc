import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/exam_session.dart';
import '../repositories/balotario_repository.dart';

final class IniciarSimulacroParams extends Equatable {
  const IniciarSimulacroParams({required this.categoriaCodigo, this.soloFalladas = false});

  final String categoriaCodigo;
  final bool soloFalladas;

  @override
  List<Object?> get props => [categoriaCodigo, soloFalladas];
}

/// Arma la sesion: resuelve las reglas de la categoria (cuantas preguntas,
/// cuanto tiempo) y pide una muestra estratificada del balotario.
final class IniciarSimulacro implements UseCase<ExamSession, IniciarSimulacroParams> {
  const IniciarSimulacro(this._repository, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  final BalotarioRepository _repository;
  final DateTime Function() _reloj;

  @override
  Future<Either<Failure, ExamSession>> call(IniciarSimulacroParams params) async {
    final categoriaOFalla = await _repository.obtenerCategoria(params.categoriaCodigo);

    return categoriaOFalla.fold<Future<Either<Failure, ExamSession>>>(
      (falla) async => Left(falla),
      (categoria) async {
        final preguntasOFalla = await _repository.obtenerPreguntasDeSimulacro(
          categoriaCodigo: categoria.codigo,
          cantidad: categoria.preguntasPorExamen,
        );

        return preguntasOFalla.fold<Either<Failure, ExamSession>>(
          Left.new,
          (preguntas) {
            if (preguntas.length < categoria.preguntasPorExamen) {
              return Left(
                BalotarioIncompletoFailure(
                  'El balotario ${categoria.codigo} tiene ${preguntas.length} preguntas '
                  'y el examen requiere ${categoria.preguntasPorExamen}.',
                ),
              );
            }
            return Right(
              ExamSession.nueva(
                id: '${categoria.codigo}-${_reloj().millisecondsSinceEpoch}',
                categoria: categoria,
                preguntas: preguntas,
                ahora: _reloj(),
              ),
            );
          },
        );
      },
    );
  }
}
