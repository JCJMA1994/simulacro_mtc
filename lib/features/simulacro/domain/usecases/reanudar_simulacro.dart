import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/time/ticker.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/exam_session.dart';
import '../repositories/session_repository.dart';

/// Recupera una sesion interrumpida. El tiempo restante NO se lee del contador
/// guardado: se recalcula contra el reloj, porque el usuario pudo estar 20
/// minutos fuera de la app y el examen real no se pausa.
final class ReanudarSimulacro implements UseCase<ExamSession?, NoParams> {
  const ReanudarSimulacro(this._repository, this._ticker);

  final SessionRepository _repository;
  final Ticker _ticker;

  /// Debajo de este umbral no vale la pena reanudar: se descarta y se ofrece
  /// empezar de nuevo.
  static const margenMinimo = Duration(minutes: 1);

  @override
  Future<Either<Failure, ExamSession?>> call(NoParams params) async {
    final recuperada = await _repository.recuperarEnCurso();

    return recuperada.fold<Future<Either<Failure, ExamSession?>>>(
      (falla) async => Left(falla),
      (sesion) async {
        if (sesion == null) return const Right(null);

        final transcurrido = _ticker.ahora().difference(sesion.iniciadoEn);
        final restante = sesion.categoria.duracion - transcurrido;

        if (restante <= margenMinimo) {
          await _repository.descartarEnCurso();
          return const Right(null);
        }
        return Right(sesion.copyWith(restante: restante));
      },
    );
  }
}
