import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam_result.dart';

abstract interface class AttemptRepository {
  Future<Either<Failure, Unit>> guardar(ExamResult resultado);

  Future<Either<Failure, List<ExamResult>>> historial(String categoriaCodigo);

  /// Ids de preguntas falladas para el modo "repasar errores".
  Future<Either<Failure, List<String>>> preguntasFalladas(String categoriaCodigo);

  /// Emite cada vez que se guarda un intento: alimenta la pantalla de progreso.
  Stream<List<ExamResult>> observarHistorial(String categoriaCodigo);
}
