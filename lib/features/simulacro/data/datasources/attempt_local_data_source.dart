import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/topic_feedback.dart';

abstract interface class AttemptLocalDataSource {
  Future<void> guardar(ExamResult resultado);
  Future<List<ExamResult>> historial(String categoriaCodigo);
  Stream<List<ExamResult>> observar(String categoriaCodigo);
  Future<void> dispose();
}

/// Persistencia simple + un BehaviorSubject por categoria para que la pantalla
/// de progreso reaccione sin volver a leer disco.
final class AttemptPrefsDataSource implements AttemptLocalDataSource {
  AttemptPrefsDataSource(this._prefs);

  final SharedPreferences _prefs;
  final _emisores = <String, BehaviorSubject<List<ExamResult>>>{};

  String _clave(String categoria) => 'intentos_$categoria';

  @override
  Future<void> guardar(ExamResult resultado) async {
    try {
      final actuales = await historial(resultado.categoriaCodigo);
      final nuevos = [resultado, ...actuales].take(50).toList();
      await _prefs.setStringList(
        _clave(resultado.categoriaCodigo),
        nuevos.map((r) => jsonEncode(_aJson(r))).toList(),
      );
      _emisores[resultado.categoriaCodigo]?.add(nuevos);
    } catch (e) {
      throw CacheException('$e');
    }
  }

  @override
  Future<List<ExamResult>> historial(String categoriaCodigo) async {
    final crudo = _prefs.getStringList(_clave(categoriaCodigo)) ?? const [];
    return crudo
        .map((s) => _deJson(jsonDecode(s) as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Stream<List<ExamResult>> observar(String categoriaCodigo) {
    final emisor = _emisores.putIfAbsent(
      categoriaCodigo,
      () => BehaviorSubject<List<ExamResult>>(),
    );
    if (!emisor.hasValue) {
      historial(categoriaCodigo).then(emisor.add).catchError(emisor.addError);
    }
    return emisor.stream;
  }

  @override
  Future<void> dispose() async {
    for (final emisor in _emisores.values) {
      await emisor.close();
    }
    _emisores.clear();
  }

  Map<String, dynamic> _aJson(ExamResult r) => {
        'categoria': r.categoriaCodigo,
        'correctas': r.correctas,
        'total': r.total,
        'minimo': r.minimoAprobatorio,
        'tiempo_seg': r.tiempoUsado.inSeconds,
        'falladas': r.preguntasFalladasIds,
        'por_topico': [
          for (final t in r.porTopico)
            {
              'codigo': t.topicoCodigo,
              'nombre': t.topicoNombre,
              'correctas': t.correctas,
              'total': t.total,
            },
        ],
      };

  ExamResult _deJson(Map<String, dynamic> j) => ExamResult(
        categoriaCodigo: j['categoria'] as String,
        correctas: j['correctas'] as int,
        total: j['total'] as int,
        minimoAprobatorio: j['minimo'] as int,
        tiempoUsado: Duration(seconds: j['tiempo_seg'] as int),
        preguntasFalladasIds: List<String>.from(j['falladas'] as List<dynamic>),
        porTopico: [
          for (final t in j['por_topico'] as List<dynamic>)
            TopicFeedback(
              topicoCodigo: (t as Map<String, dynamic>)['codigo'] as String,
              topicoNombre: t['nombre'] as String,
              correctas: t['correctas'] as int,
              total: t['total'] as int,
            ),
        ],
      );
}
