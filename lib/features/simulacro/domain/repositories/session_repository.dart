import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam_session.dart';

/// Persistencia de la sesion EN CURSO (distinta del historial de intentos).
/// Existe por una sola razon: si el SO mata el proceso en el minuto 30, el
/// usuario no puede perder 30 minutos de examen.
abstract interface class SessionRepository {
  Future<Either<Failure, Unit>> guardarEnCurso(ExamSession sesion);
  Future<Either<Failure, ExamSession?>> recuperarEnCurso();
  Future<Either<Failure, Unit>> descartarEnCurso();
}
