/// Puerto de tiempo. El bloc no crea streams periodicos por su cuenta: pide
/// ticks a este puerto. En test se inyecta un FakeTicker y un examen de 40
/// minutos corre en milisegundos, sin esperas reales ni flakiness.
abstract interface class Ticker {
  Stream<Duration> cuentaRegresiva(Duration total);
  DateTime ahora();
}

final class RelojTicker implements Ticker {
  const RelojTicker();

  @override
  Stream<Duration> cuentaRegresiva(Duration total) =>
      Stream<int>.periodic(const Duration(seconds: 1), (i) => i + 1)
          .map((s) => total - Duration(seconds: s))
          .takeWhile((restante) => restante >= Duration.zero);

  @override
  DateTime ahora() => DateTime.now();
}
