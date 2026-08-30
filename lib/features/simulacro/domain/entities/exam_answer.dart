import 'package:equatable/equatable.dart';

final class ExamAnswer extends Equatable {
  const ExamAnswer({
    required this.preguntaId,
    required this.topicoCodigo,
    required this.indiceElegido,
    required this.esCorrecta,
    required this.tiempoRespuesta,
    this.marcada = false,
  });

  final String preguntaId;
  final String topicoCodigo;
  final int? indiceElegido;
  final bool esCorrecta;
  final Duration tiempoRespuesta;
  final bool marcada;

  bool get respondida => indiceElegido != null;

  ExamAnswer copyWith({int? indiceElegido, bool? esCorrecta, bool? marcada}) => ExamAnswer(
        preguntaId: preguntaId,
        topicoCodigo: topicoCodigo,
        indiceElegido: indiceElegido ?? this.indiceElegido,
        esCorrecta: esCorrecta ?? this.esCorrecta,
        tiempoRespuesta: tiempoRespuesta,
        marcada: marcada ?? this.marcada,
      );

  @override
  List<Object?> get props => [preguntaId, indiceElegido, esCorrecta, marcada];
}
