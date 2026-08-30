import 'package:simulacro_mtc/core/time/ticker.dart';

/// Ticker de prueba: dispara los ticks a mano. Un examen de 40 minutos se
/// simula en microsegundos y sin esperas reales.
final class FakeTicker implements Ticker {
  FakeTicker({DateTime? ahoraFijo}) : _ahora = ahoraFijo ?? DateTime(2026, 1, 1, 9);

  DateTime _ahora;

  @override
  DateTime ahora() => _ahora;

  void avanzarReloj(Duration d) => _ahora = _ahora.add(d);

  @override
  Stream<Duration> cuentaRegresiva(Duration total) async* {
    var restante = total;
    while (restante > Duration.zero) {
      restante -= const Duration(seconds: 1);
      yield restante;
    }
  }
}
