import 'package:equatable/equatable.dart';

import 'exam_answer.dart';
import 'license_category.dart';
import 'question.dart';

/// Estado inmutable de un simulacro en curso.
final class ExamSession extends Equatable {
  const ExamSession({
    required this.id,
    required this.categoria,
    required this.preguntas,
    required this.respuestas,
    required this.indiceActual,
    required this.iniciadoEn,
    required this.restante,
  });

  factory ExamSession.nueva({
    required String id,
    required LicenseCategory categoria,
    required List<Question> preguntas,
    required DateTime ahora,
  }) =>
      ExamSession(
        id: id,
        categoria: categoria,
        preguntas: preguntas,
        respuestas: const {},
        indiceActual: 0,
        iniciadoEn: ahora,
        restante: categoria.duracion,
      );

  final String id;
  final LicenseCategory categoria;
  final List<Question> preguntas;
  final Map<String, ExamAnswer> respuestas;
  final int indiceActual;
  final DateTime iniciadoEn;
  final Duration restante;

  Question get preguntaActual => preguntas[indiceActual];
  int get respondidas => respuestas.values.where((r) => r.respondida).length;
  double get progreso => preguntas.isEmpty ? 0 : (indiceActual + 1) / preguntas.length;
  bool get esUltima => indiceActual == preguntas.length - 1;
  bool get tiempoAgotado => restante <= Duration.zero;

  ExamSession copyWith({
    Map<String, ExamAnswer>? respuestas,
    int? indiceActual,
    Duration? restante,
  }) =>
      ExamSession(
        id: id,
        categoria: categoria,
        preguntas: preguntas,
        respuestas: respuestas ?? this.respuestas,
        indiceActual: indiceActual ?? this.indiceActual,
        iniciadoEn: iniciadoEn,
        restante: restante ?? this.restante,
      );

  @override
  List<Object?> get props => [id, indiceActual, respuestas, restante];
}
