import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/license_category.dart';
import '../repositories/balotario_repository.dart';

final class ObtenerCategorias implements UseCase<List<LicenseCategory>, NoParams> {
  const ObtenerCategorias(this._repository);

  final BalotarioRepository _repository;

  @override
  Future<Either<Failure, List<LicenseCategory>>> call(NoParams params) =>
      _repository.obtenerCategorias();
}
