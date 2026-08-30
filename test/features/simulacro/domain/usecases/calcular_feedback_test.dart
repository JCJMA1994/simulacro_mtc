import 'package:flutter_test/flutter_test.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/exam_answer.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/exam_session.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/license_category.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/question.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/topic_feedback.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/topico.dart';
import 'package:simulacro_mtc/features/simulacro/domain/usecases/calcular_feedback.dart';

void main() {
  const categoria = LicenseCategory(
    codigo: 'A-I',
    nombre: 'Clase A Categoria I',
    clase: 'A',
    vehiculos: 'M1, M2, N1',
    esProfesional: false,
    preguntasPorExamen: 4,
    minimoAprobatorio: 3,
    duracion: Duration(minutes: 40),
    topicos: [
      Topico(codigo: 'SENIALES', nombre: 'Senales'),
      Topico(codigo: 'VELOCIDAD', nombre: 'Velocidad'),
    ],
    urlBalotarioOficial: 'https://gob.pe',
  );

  Question pregunta(String id, String topico) => Question(
        id: id,
        numero: 1,
        categoriaCodigo: 'A-I',
        topicoCodigo: topico,
        enunciado: 'x',
        opciones: const ['a', 'b'],
        indiceCorrecto: 0,
      );

  test('desglosa el dominio por topico y marca desaprobado', () {
    final preguntas = [
      pregunta('1', 'SENIALES'),
      pregunta('2', 'SENIALES'),
      pregunta('3', 'VELOCIDAD'),
      pregunta('4', 'VELOCIDAD'),
    ];

    final sesion = ExamSession(
      id: 's1',
      categoria: categoria,
      preguntas: preguntas,
      indiceActual: 3,
      iniciadoEn: DateTime(2026),
      restante: const Duration(minutes: 10),
      respuestas: const {
        '1': ExamAnswer(
          preguntaId: '1',
          topicoCodigo: 'SENIALES',
          indiceElegido: 0,
          esCorrecta: true,
          tiempoRespuesta: Duration(seconds: 5),
        ),
        '2': ExamAnswer(
          preguntaId: '2',
          topicoCodigo: 'SENIALES',
          indiceElegido: 0,
          esCorrecta: true,
          tiempoRespuesta: Duration(seconds: 5),
        ),
        '3': ExamAnswer(
          preguntaId: '3',
          topicoCodigo: 'VELOCIDAD',
          indiceElegido: 1,
          esCorrecta: false,
          tiempoRespuesta: Duration(seconds: 5),
        ),
      },
    );

    final resultado = const CalcularFeedback()(sesion).getOrElse(() => throw StateError('x'));

    expect(resultado.correctas, 2);
    expect(resultado.aprobado, isFalse);
    expect(resultado.faltantes, 1);
    expect(resultado.tiempoUsado, const Duration(minutes: 30));
    expect(resultado.preguntasFalladasIds, ['3', '4']);
    expect(resultado.puntoDebil?.topicoCodigo, 'VELOCIDAD');
    expect(
      resultado.porTopico.firstWhere((t) => t.topicoCodigo == 'SENIALES').nivel,
      NivelDominio.solido,
    );
  });
}
