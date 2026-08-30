import 'package:equatable/equatable.dart';

import 'topico.dart';

/// Categoria de licencia del MTC (A-I, A-IIa, ..., B-IIc).
/// Las reglas del examen viven aqui porque varian por categoria:
/// B-IIa se rinde con 35 preguntas y 30 aciertos; el resto, 40 y 35.
base class LicenseCategory extends Equatable {
  const LicenseCategory({
    required this.codigo,
    required this.nombre,
    required this.clase,
    required this.vehiculos,
    required this.esProfesional,
    required this.preguntasPorExamen,
    required this.minimoAprobatorio,
    required this.duracion,
    required this.topicos,
    required this.urlBalotarioOficial,
  });

  final String codigo;
  final String nombre;
  final String clase;
  final String vehiculos;
  final bool esProfesional;
  final int preguntasPorExamen;
  final int minimoAprobatorio;
  final Duration duracion;
  final List<Topico> topicos;
  final String urlBalotarioOficial;

  double get exigencia => minimoAprobatorio / preguntasPorExamen;
  int get erroresPermitidos => preguntasPorExamen - minimoAprobatorio;

  @override
  List<Object?> get props => [codigo, preguntasPorExamen, minimoAprobatorio, duracion];
}
