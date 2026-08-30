import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/exam_result.dart';
import '../repositories/attempt_repository.dart';

final class ObtenerHistorialParams extends Equatable {
  const ObtenerHistorialParams({required this.categoriaCodigo});

  final String categoriaCodigo;

  @override
  List<Object?> get props => [categoriaCodigo];
}

final class ObtenerHistorial implements UseCase<List<ExamResult>, ObtenerHistorialParams> {
  const ObtenerHistorial(this._repository);

  final AttemptRepository _repository;

  @override
  Future<Either<Failure, List<ExamResult>>> call(ObtenerHistorialParams params) {
    return _repository.historial(params.categoriaCodigo);
  }
}
