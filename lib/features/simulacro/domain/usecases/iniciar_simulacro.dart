import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/exam_session.dart';
import '../entities/question.dart';
import '../repositories/attempt_repository.dart';
import '../repositories/balotario_repository.dart';

final class IniciarSimulacroParams extends Equatable {
  const IniciarSimulacroParams({required this.categoriaCodigo, this.soloFalladas = false});

  final String categoriaCodigo;
  final bool soloFalladas;

  @override
  List<Object?> get props => [categoriaCodigo, soloFalladas];
}

/// Arma la sesion: resuelve las reglas de la categoria (cuantas preguntas,
/// cuanto tiempo) y pide una muestra estratificada del balotario o solo falladas.
final class IniciarSimulacro implements UseCase<ExamSession, IniciarSimulacroParams> {
  const IniciarSimulacro(
    this._repository, {
    AttemptRepository? attemptRepository,
    DateTime Function()? reloj,
  })  : _attemptRepository = attemptRepository,
        _reloj = reloj ?? DateTime.now;

  final BalotarioRepository _repository;
  final AttemptRepository? _attemptRepository;
  final DateTime Function() _reloj;

  @override
  Future<Either<Failure, ExamSession>> call(IniciarSimulacroParams params) async {
    final categoriaOFalla = await _repository.obtenerCategoria(params.categoriaCodigo);

    return categoriaOFalla.fold<Future<Either<Failure, ExamSession>>>(
      (falla) async => Left(falla),
      (categoria) async {
        List<Question> preguntasSeleccionadas = [];

        if (params.soloFalladas && _attemptRepository != null) {
          final falladasRes = await _attemptRepository.preguntasFalladas(categoria.codigo);
          final falladasIds = falladasRes.getOrElse(() => []);
          if (falladasIds.isNotEmpty) {
            final balotarioCompletoRes = await _repository.obtenerBalotario(categoria.codigo);
            final banco = balotarioCompletoRes.getOrElse(() => []);
            preguntasSeleccionadas = banco.where((q) => falladasIds.contains(q.id)).toList();
          }
        }

        if (preguntasSeleccionadas.isEmpty) {
          final preguntasOFalla = await _repository.obtenerPreguntasDeSimulacro(
            categoriaCodigo: categoria.codigo,
            cantidad: categoria.preguntasPorExamen,
          );

          if (preguntasOFalla.isLeft()) {
            return Left(preguntasOFalla.fold((l) => l, (_) => const CacheFailure('Error')));
          }
          preguntasSeleccionadas = preguntasOFalla.getOrElse(() => []);
        }

        if (preguntasSeleccionadas.isEmpty) {
          return Left(
            BalotarioIncompletoFailure(
              'No hay preguntas disponibles para la categoría ${categoria.codigo}.',
            ),
          );
        }

        return Right(
          ExamSession.nueva(
            id: '${categoria.codigo}-${_reloj().millisecondsSinceEpoch}',
            categoria: categoria,
            preguntas: preguntasSeleccionadas,
            ahora: _reloj(),
          ),
        );
      },
    );
  }
}
