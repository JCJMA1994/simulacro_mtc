import '../../domain/entities/license_category.dart';
import '../../domain/entities/topico.dart';

final class LicenseCategoryModel extends LicenseCategory {
  const LicenseCategoryModel({
    required super.codigo,
    required super.nombre,
    required super.clase,
    required super.vehiculos,
    required super.esProfesional,
    required super.preguntasPorExamen,
    required super.minimoAprobatorio,
    required super.duracion,
    required super.topicos,
    required super.urlBalotarioOficial,
  });

  factory LicenseCategoryModel.fromJson(
    Map<String, dynamic> json,
    Map<String, String> nombresTopico,
  ) {
    final codigos = List<String>.from(json['topicos'] as List<dynamic>);
    return LicenseCategoryModel(
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      clase: json['clase'] as String,
      vehiculos: json['vehiculos'] as String,
      esProfesional: (json['tipo'] as String) == 'profesional',
      preguntasPorExamen: json['preguntas_examen'] as int,
      minimoAprobatorio: json['minimo_aprobatorio'] as int,
      duracion: Duration(minutes: json['duracion_minutos'] as int),
      topicos: [
        for (final c in codigos) Topico(codigo: c, nombre: nombresTopico[c] ?? c),
      ],
      urlBalotarioOficial: json['pdf'] as String,
    );
  }
}
