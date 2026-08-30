import 'package:equatable/equatable.dart';

base class Question extends Equatable {
  const Question({
    required this.id,
    required this.numero,
    required this.categoriaCodigo,
    required this.topicoCodigo,
    required this.enunciado,
    required this.opciones,
    required this.indiceCorrecto,
    this.explicacion,
    this.imagenAsset,
  });

  final String id;
  final int numero;
  final String categoriaCodigo;
  final String topicoCodigo;
  final String enunciado;
  final List<String> opciones;
  final int indiceCorrecto;
  final String? explicacion;
  final String? imagenAsset;

  bool esCorrecta(int indice) => indice == indiceCorrecto;

  @override
  List<Object?> get props => [id, indiceCorrecto];
}
