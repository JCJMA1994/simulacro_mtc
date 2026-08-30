import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/exam_result.dart';
import '../entities/exam_session.dart';
import '../entities/topic_feedback.dart';

/// Regla de negocio pura: convierte una sesion terminada en el resultado
/// con desglose por topico. Sin IO, 100% testeable.
final class CalcularFeedback implements SyncUseCase<ExamResult, ExamSession> {
  const CalcularFeedback();

  @override
  Either<Failure, ExamResult> call(ExamSession sesion) {
    final categoria = sesion.categoria;
    final nombresTopico = {for (final t in categoria.topicos) t.codigo: t.nombre};

    final totalPorTopico = <String, int>{};
    final correctasPorTopico = <String, int>{};
    final falladas = <String>[];
    var correctas = 0;

    for (final pregunta in sesion.preguntas) {
      final topico = pregunta.topicoCodigo;
      totalPorTopico.update(topico, (v) => v + 1, ifAbsent: () => 1);

      final respuesta = sesion.respuestas[pregunta.id];
      final acerto = respuesta?.esCorrecta ?? false;
      if (acerto) {
        correctas++;
        correctasPorTopico.update(topico, (v) => v + 1, ifAbsent: () => 1);
      } else {
        falladas.add(pregunta.id);
      }
    }

    final porTopico = totalPorTopico.entries
        .map(
          (e) => TopicFeedback(
            topicoCodigo: e.key,
            topicoNombre: nombresTopico[e.key] ?? e.key,
            correctas: correctasPorTopico[e.key] ?? 0,
            total: e.value,
          ),
        )
        .toList(growable: false);

    return Right(
      ExamResult(
        categoriaCodigo: categoria.codigo,
        correctas: correctas,
        total: sesion.preguntas.length,
        minimoAprobatorio: categoria.minimoAprobatorio,
        tiempoUsado: categoria.duracion - sesion.restante,
        porTopico: porTopico,
        preguntasFalladasIds: falladas,
      ),
    );
  }
}
