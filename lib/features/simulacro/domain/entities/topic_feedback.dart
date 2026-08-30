import 'package:equatable/equatable.dart';

enum NivelDominio { critico, enRiesgo, solido }

final class TopicFeedback extends Equatable {
  const TopicFeedback({
    required this.topicoCodigo,
    required this.topicoNombre,
    required this.correctas,
    required this.total,
  });

  final String topicoCodigo;
  final String topicoNombre;
  final int correctas;
  final int total;

  double get dominio => total == 0 ? 0 : correctas / total;

  NivelDominio get nivel => switch (dominio) {
        >= 0.9 => NivelDominio.solido,
        >= 0.7 => NivelDominio.enRiesgo,
        _ => NivelDominio.critico,
      };

  @override
  List<Object?> get props => [topicoCodigo, correctas, total];
}
