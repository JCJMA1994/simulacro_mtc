import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/exam_session.dart';
import '../repositories/session_repository.dart';

/// Se dispara en cada respuesta y en cada cambio de pregunta. En el bloc se
/// registra con el transformer `debounce(700ms)`: escribir en disco en cada
/// tick del cronometro seria un desperdicio, y perder 700 ms de examen no
/// le cambia la vida a nadie.
final class AutoguardarSesion implements UseCase<Unit, ExamSession> {
  const AutoguardarSesion(this._repository);

  final SessionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ExamSession params) =>
      _repository.guardarEnCurso(params);
}
