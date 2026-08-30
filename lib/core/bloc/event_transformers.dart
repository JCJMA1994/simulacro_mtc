import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

/// Transformers de eventos basados en RxDart.
///
/// Por que importan aqui:
///  * `restartable` cancela el handler anterior: correcto para el tick del
///    cronometro y para iniciar un simulacro (si el usuario cambia de
///    categoria, el intento anterior debe morir).
///  * `droppable` ignora eventos mientras hay uno en vuelo: evita que un doble
///    tap en "Siguiente" salte dos preguntas.
///  * `debounce` agrupa rafagas: util al escribir en el buscador del balotario.
EventTransformer<E> restartable<E>() => (eventos, mapper) => eventos.switchMap(mapper);

EventTransformer<E> droppable<E>() => (eventos, mapper) => eventos.exhaustMap(mapper);

EventTransformer<E> secuencial<E>() => (eventos, mapper) => eventos.asyncExpand(mapper);

EventTransformer<E> debounce<E>([Duration duracion = const Duration(milliseconds: 300)]) =>
    (eventos, mapper) => eventos.debounceTime(duracion).switchMap(mapper);
