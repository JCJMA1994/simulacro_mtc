part of 'exam_bloc.dart';

sealed class ExamEvent extends Equatable {
  const ExamEvent();

  @override
  List<Object?> get props => const [];
}

final class SimulacroIniciado extends ExamEvent {
  const SimulacroIniciado(this.categoriaCodigo, {this.soloFalladas = false});
  final String categoriaCodigo;
  final bool soloFalladas;

  @override
  List<Object?> get props => [categoriaCodigo, soloFalladas];
}

/// Se dispara al abrir la app: si hay una sesion interrumpida, la restaura.
final class SimulacroReanudado extends ExamEvent {
  const SimulacroReanudado();
}

final class SimulacroDescartado extends ExamEvent {
  const SimulacroDescartado();
}

final class OpcionSeleccionada extends ExamEvent {
  const OpcionSeleccionada(this.indice);
  final int indice;

  @override
  List<Object?> get props => [indice];
}

final class PreguntaMarcada extends ExamEvent {
  const PreguntaMarcada();
}

final class AvanzoPregunta extends ExamEvent {
  const AvanzoPregunta();
}

final class RetrocedioPregunta extends ExamEvent {
  const RetrocedioPregunta();
}

final class SaltoAPregunta extends ExamEvent {
  const SaltoAPregunta(this.indice);
  final int indice;

  @override
  List<Object?> get props => [indice];
}

final class ExamenFinalizado extends ExamEvent {
  const ExamenFinalizado({this.porTiempo = false});
  final bool porTiempo;

  @override
  List<Object?> get props => [porTiempo];
}

/// Interno: lo emite el Ticker cada segundo.
final class _CronometroActualizado extends ExamEvent {
  const _CronometroActualizado(this.restante);
  final Duration restante;

  @override
  List<Object?> get props => [restante];
}

/// Interno: persiste la sesion. Con debounce, no en cada tick.
final class _SesionAutoguardada extends ExamEvent {
  const _SesionAutoguardada();
}
