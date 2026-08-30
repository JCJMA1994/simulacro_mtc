import 'package:equatable/equatable.dart';

import 'topic_feedback.dart';

final class ExamResult extends Equatable {
  const ExamResult({
    required this.categoriaCodigo,
    required this.correctas,
    required this.total,
    required this.minimoAprobatorio,
    required this.tiempoUsado,
    required this.porTopico,
    required this.preguntasFalladasIds,
  });

  final String categoriaCodigo;
  final int correctas;
  final int total;
  final int minimoAprobatorio;
  final Duration tiempoUsado;
  final List<TopicFeedback> porTopico;
  final List<String> preguntasFalladasIds;

  bool get aprobado => correctas >= minimoAprobatorio;
  int get faltantes => aprobado ? 0 : minimoAprobatorio - correctas;

  /// Topicos ordenados de peor a mejor: es lo que la UI muestra primero.
  List<TopicFeedback> get prioridadDeRepaso =>
      [...porTopico]..sort((a, b) => a.dominio.compareTo(b.dominio));

  TopicFeedback? get puntoDebil {
    final orden = prioridadDeRepaso;
    if (orden.isEmpty) return null;
    return orden.first.nivel == NivelDominio.solido ? null : orden.first;
  }

  @override
  List<Object?> get props => [categoriaCodigo, correctas, total, tiempoUsado];
}
