import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/exam_result.dart';
import '../repositories/attempt_repository.dart';

final class GuardarIntento implements UseCase<Unit, ExamResult> {
  const GuardarIntento(this._repository);

  final AttemptRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ExamResult params) => _repository.guardar(params);
}
