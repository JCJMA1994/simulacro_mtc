import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/bloc/event_transformers.dart';
import '../../../../../core/time/ticker.dart';
import '../../../domain/entities/exam_answer.dart';
import '../../../domain/entities/exam_result.dart';
import '../../../domain/entities/exam_session.dart';
import '../../../domain/usecases/autoguardar_sesion.dart';
import '../../../domain/usecases/calcular_feedback.dart';
import '../../../domain/usecases/guardar_intento.dart';
import '../../../domain/usecases/iniciar_simulacro.dart';
import '../../../domain/usecases/reanudar_simulacro.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/repositories/session_repository.dart';

part 'exam_event.dart';
part 'exam_state.dart';

/// Orquesta un simulacro. No conoce widgets ni JSON: solo entidades y casos
/// de uso. El tiempo entra por el puerto [Ticker], asi que los tests corren
/// un examen de 40 minutos en milisegundos.
final class ExamBloc extends Bloc<ExamEvent, ExamState> {
  ExamBloc({
    required IniciarSimulacro iniciarSimulacro,
    required ReanudarSimulacro reanudarSimulacro,
    required AutoguardarSesion autoguardarSesion,
    required CalcularFeedback calcularFeedback,
    required GuardarIntento guardarIntento,
    required SessionRepository sessionRepository,
    required Ticker ticker,
  })  : _iniciarSimulacro = iniciarSimulacro,
        _reanudarSimulacro = reanudarSimulacro,
        _autoguardarSesion = autoguardarSesion,
        _calcularFeedback = calcularFeedback,
        _guardarIntento = guardarIntento,
        _sessionRepository = sessionRepository,
        _ticker = ticker,
        super(const ExamState()) {
    on<SimulacroIniciado>(_alIniciar, transformer: restartable());
    on<SimulacroReanudado>(_alReanudar, transformer: restartable());
    on<SimulacroDescartado>(_alDescartar, transformer: droppable());
    on<OpcionSeleccionada>(_alResponder, transformer: secuencial());
    on<PreguntaMarcada>(_alMarcar, transformer: secuencial());
    on<AvanzoPregunta>(_alAvanzar, transformer: droppable());
    on<RetrocedioPregunta>(_alRetroceder, transformer: droppable());
    on<SaltoAPregunta>(_alSaltar, transformer: droppable());
    on<ExamenFinalizado>(_alFinalizar, transformer: droppable());
    on<_CronometroActualizado>(_alTick, transformer: secuencial());
    on<_SesionAutoguardada>(
      _alAutoguardar,
      transformer: debounce(const Duration(milliseconds: 700)),
    );
  }

  final IniciarSimulacro _iniciarSimulacro;
  final ReanudarSimulacro _reanudarSimulacro;
  final AutoguardarSesion _autoguardarSesion;
  final CalcularFeedback _calcularFeedback;
  final GuardarIntento _guardarIntento;
  final SessionRepository _sessionRepository;
  final Ticker _ticker;

  StreamSubscription<Duration>? _cronometro;

  // ------------------------------------------------------------ ciclo de vida

  Future<void> _alIniciar(SimulacroIniciado evento, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: ExamStatus.cargando));

    final resultado = await _iniciarSimulacro(
      IniciarSimulacroParams(categoriaCodigo: evento.categoriaCodigo),
    );

    resultado.fold(
      (falla) => emit(state.copyWith(status: ExamStatus.error, mensajeError: falla.mensaje)),
      (sesion) {
        emit(ExamState(status: ExamStatus.enCurso, sesion: sesion));
        _arrancarCronometro(sesion.restante);
        add(const _SesionAutoguardada());
      },
    );
  }

  Future<void> _alReanudar(SimulacroReanudado evento, Emitter<ExamState> emit) async {
    final resultado = await _reanudarSimulacro(const NoParams());

    resultado.fold(
      (falla) => emit(state.copyWith(status: ExamStatus.error, mensajeError: falla.mensaje)),
      (sesion) {
        if (sesion == null) {
          emit(const ExamState());
          return;
        }
        emit(ExamState(status: ExamStatus.enCurso, sesion: sesion));
        _arrancarCronometro(sesion.restante);
      },
    );
  }

  Future<void> _alDescartar(SimulacroDescartado evento, Emitter<ExamState> emit) async {
    await _cronometro?.cancel();
    await _sessionRepository.descartarEnCurso();
    emit(const ExamState());
  }

  /// El cronometro pide ticks al puerto: el bloc nunca crea streams de tiempo.
  void _arrancarCronometro(Duration restante) {
    _cronometro?.cancel();
    _cronometro = _ticker.cuentaRegresiva(restante).listen(
          (r) => add(_CronometroActualizado(r)),
          onDone: () => add(const ExamenFinalizado(porTiempo: true)),
        );
  }

  void _alTick(_CronometroActualizado evento, Emitter<ExamState> emit) {
    final sesion = state.sesion;
    if (sesion == null || state.status != ExamStatus.enCurso) return;
    emit(state.copyWith(sesion: sesion.copyWith(restante: evento.restante)));
  }

  Future<void> _alAutoguardar(_SesionAutoguardada evento, Emitter<ExamState> emit) async {
    final sesion = state.sesion;
    if (sesion == null || !state.enCurso) return;
    // Fallar al persistir no debe interrumpir el examen: se registra y sigue.
    await _autoguardarSesion(sesion);
  }

  // ------------------------------------------------------------- interaccion

  void _alResponder(OpcionSeleccionada evento, Emitter<ExamState> emit) {
    final sesion = state.sesion;
    if (sesion == null || !state.enCurso) return;

    final pregunta = sesion.preguntaActual;
    final previa = sesion.respuestas[pregunta.id];
    final respuestas = Map<String, ExamAnswer>.from(sesion.respuestas)
      ..[pregunta.id] = ExamAnswer(
        preguntaId: pregunta.id,
        topicoCodigo: pregunta.topicoCodigo,
        indiceElegido: evento.indice,
        esCorrecta: pregunta.esCorrecta(evento.indice),
        tiempoRespuesta: sesion.categoria.duracion - sesion.restante,
        marcada: previa?.marcada ?? false,
      );

    emit(state.copyWith(sesion: sesion.copyWith(respuestas: respuestas)));
    add(const _SesionAutoguardada());
  }

  void _alMarcar(PreguntaMarcada evento, Emitter<ExamState> emit) {
    final sesion = state.sesion;
    if (sesion == null || !state.enCurso) return;

    final pregunta = sesion.preguntaActual;
    final actual = sesion.respuestas[pregunta.id];
    final respuestas = Map<String, ExamAnswer>.from(sesion.respuestas)
      ..[pregunta.id] = (actual ??
              ExamAnswer(
                preguntaId: pregunta.id,
                topicoCodigo: pregunta.topicoCodigo,
                indiceElegido: null,
                esCorrecta: false,
                tiempoRespuesta: Duration.zero,
              ))
          .copyWith(marcada: !(actual?.marcada ?? false));

    emit(state.copyWith(sesion: sesion.copyWith(respuestas: respuestas)));
    add(const _SesionAutoguardada());
  }

  void _alAvanzar(AvanzoPregunta evento, Emitter<ExamState> emit) {
    final sesion = state.sesion;
    if (sesion == null || !state.enCurso || sesion.esUltima) return;
    emit(state.copyWith(sesion: sesion.copyWith(indiceActual: sesion.indiceActual + 1)));
    add(const _SesionAutoguardada());
  }

  void _alRetroceder(RetrocedioPregunta evento, Emitter<ExamState> emit) {
    final sesion = state.sesion;
    if (sesion == null || !state.enCurso || sesion.indiceActual == 0) return;
    emit(state.copyWith(sesion: sesion.copyWith(indiceActual: sesion.indiceActual - 1)));
    add(const _SesionAutoguardada());
  }

  void _alSaltar(SaltoAPregunta evento, Emitter<ExamState> emit) {
    final sesion = state.sesion;
    if (sesion == null || !state.enCurso) return;
    if (evento.indice < 0 || evento.indice >= sesion.preguntas.length) return;
    emit(state.copyWith(sesion: sesion.copyWith(indiceActual: evento.indice)));
    add(const _SesionAutoguardada());
  }

  // ------------------------------------------------------------- calificacion

  Future<void> _alFinalizar(ExamenFinalizado evento, Emitter<ExamState> emit) async {
    final sesion = state.sesion;
    if (sesion == null || state.status == ExamStatus.terminado) return;

    await _cronometro?.cancel();
    emit(state.copyWith(status: ExamStatus.calificando));

    final calificado = _calcularFeedback(sesion);

    await calificado.fold<Future<void>>(
      (falla) async =>
          emit(state.copyWith(status: ExamStatus.error, mensajeError: falla.mensaje)),
      (resultado) async {
        await _guardarIntento(resultado);
        await _sessionRepository.descartarEnCurso();
        emit(state.copyWith(status: ExamStatus.terminado, resultado: resultado));
      },
    );
  }

  @override
  Future<void> close() async {
    await _cronometro?.cancel();
    return super.close();
  }
}
