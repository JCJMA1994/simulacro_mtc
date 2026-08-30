import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/exam_answer.dart';
import '../../domain/entities/exam_session.dart';
import '../../domain/entities/license_category.dart';
import '../models/question_model.dart';

abstract interface class SessionLocalDataSource {
  Future<void> guardar(ExamSession sesion);
  Future<ExamSession?> recuperar(
    Future<LicenseCategory> Function(String codigo) resolverCategoria,
  );
  Future<void> descartar();
}

/// Guarda la sesion en curso serializada. Solo hay una a la vez: empezar un
/// simulacro nuevo pisa el anterior, igual que en el examen real.
final class SessionPrefsDataSource implements SessionLocalDataSource {
  const SessionPrefsDataSource(this._prefs);

  static const _clave = 'sesion_en_curso';

  final SharedPreferences _prefs;

  @override
  Future<void> guardar(ExamSession sesion) async {
    try {
      await _prefs.setString(
        _clave,
        jsonEncode({
          'id': sesion.id,
          'categoria': sesion.categoria.codigo,
          'indice': sesion.indiceActual,
          'iniciado_en': sesion.iniciadoEn.toIso8601String(),
          'restante_seg': sesion.restante.inSeconds,
          'preguntas': [
            for (final p in sesion.preguntas)
              QuestionModel(
                id: p.id,
                numero: p.numero,
                categoriaCodigo: p.categoriaCodigo,
                topicoCodigo: p.topicoCodigo,
                enunciado: p.enunciado,
                opciones: p.opciones,
                indiceCorrecto: p.indiceCorrecto,
                explicacion: p.explicacion,
                imagenAsset: p.imagenAsset,
              ).toJson(),
          ],
          'respuestas': [
            for (final r in sesion.respuestas.values)
              {
                'pregunta_id': r.preguntaId,
                'topico': r.topicoCodigo,
                'elegida': r.indiceElegido,
                'correcta': r.esCorrecta,
                'tiempo_seg': r.tiempoRespuesta.inSeconds,
                'marcada': r.marcada,
              },
          ],
        }),
      );
    } catch (e) {
      throw CacheException('$e');
    }
  }

  @override
  Future<ExamSession?> recuperar(
    Future<LicenseCategory> Function(String codigo) resolverCategoria,
  ) async {
    final crudo = _prefs.getString(_clave);
    if (crudo == null) return null;

    try {
      final j = jsonDecode(crudo) as Map<String, dynamic>;
      final categoria = await resolverCategoria(j['categoria'] as String);

      return ExamSession(
        id: j['id'] as String,
        categoria: categoria,
        indiceActual: j['indice'] as int,
        iniciadoEn: DateTime.parse(j['iniciado_en'] as String),
        restante: Duration(seconds: j['restante_seg'] as int),
        preguntas: [
          for (final p in j['preguntas'] as List<dynamic>)
            QuestionModel.fromJson(p as Map<String, dynamic>),
        ],
        respuestas: {
          for (final r in j['respuestas'] as List<dynamic>)
            (r as Map<String, dynamic>)['pregunta_id'] as String: ExamAnswer(
              preguntaId: r['pregunta_id'] as String,
              topicoCodigo: r['topico'] as String,
              indiceElegido: r['elegida'] as int?,
              esCorrecta: r['correcta'] as bool,
              tiempoRespuesta: Duration(seconds: r['tiempo_seg'] as int),
              marcada: r['marcada'] as bool,
            ),
        },
      );
    } catch (e) {
      // Un JSON corrupto no debe bloquear la app para siempre.
      await descartar();
      return null;
    }
  }

  @override
  Future<void> descartar() async => _prefs.remove(_clave);
}
