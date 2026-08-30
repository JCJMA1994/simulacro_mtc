import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.mensaje);
  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}

final class CacheFailure extends Failure {
  const CacheFailure([super.mensaje = 'No se pudo leer el balotario local']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.mensaje = 'Error de servidor']);
}

final class BalotarioIncompletoFailure extends Failure {
  const BalotarioIncompletoFailure(super.mensaje);
}
