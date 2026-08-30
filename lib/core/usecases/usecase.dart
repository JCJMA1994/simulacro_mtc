import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Contrato unico para todos los casos de uso.
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Variante sincrona: util para calculos puros de dominio (p. ej. feedback).
abstract interface class SyncUseCase<T, Params> {
  Either<Failure, T> call(Params params);
}

final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
