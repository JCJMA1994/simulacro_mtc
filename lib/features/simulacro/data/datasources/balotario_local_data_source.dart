import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/error/exceptions.dart';
import '../models/license_category_model.dart';
import '../models/question_model.dart';

abstract interface class BalotarioLocalDataSource {
  Future<List<LicenseCategoryModel>> categorias();
  Future<List<QuestionModel>> balotario(String categoriaCodigo);
  Future<List<QuestionModel>> muestraEstratificada({
    required String categoriaCodigo,
    required int cantidad,
    List<String> excluirIds,
  });
}

final class BalotarioAssetDataSource implements BalotarioLocalDataSource {
  BalotarioAssetDataSource({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  final _cacheBalotarios = <String, List<QuestionModel>>{};
  List<LicenseCategoryModel>? _cacheCategorias;

  static const _rutaCatalogo = 'assets/balotarios/catalogo_categorias.json';

  @override
  Future<List<LicenseCategoryModel>> categorias() async {
    if (_cacheCategorias != null) return _cacheCategorias!;
    try {
      final crudo = jsonDecode(await rootBundle.loadString(_rutaCatalogo)) as Map<String, dynamic>;
      final nombres = {
        for (final t in crudo['topicos'] as List<dynamic>)
          (t as Map<String, dynamic>)['codigo'] as String: t['nombre'] as String,
      };
      return _cacheCategorias = [
        for (final c in crudo['categorias'] as List<dynamic>)
          LicenseCategoryModel.fromJson(c as Map<String, dynamic>, nombres),
      ];
    } catch (e) {
      throw CacheException('$e');
    }
  }

  @override
  Future<List<QuestionModel>> balotario(String categoriaCodigo) async {
    final enCache = _cacheBalotarios[categoriaCodigo];
    if (enCache != null) return enCache;
    try {
      final crudo = jsonDecode(
        await rootBundle.loadString('assets/balotarios/balotario_$categoriaCodigo.json'),
      ) as Map<String, dynamic>;
      return _cacheBalotarios[categoriaCodigo] = [
        for (final p in crudo['preguntas'] as List<dynamic>)
          QuestionModel.fromJson(p as Map<String, dynamic>),
      ];
    } catch (e) {
      throw CacheException('No se pudo cargar el balotario $categoriaCodigo: $e');
    }
  }

  /// Reparte la muestra proporcionalmente entre los topicos presentes en el
  /// banco, para que el simulacro se parezca a la distribucion real del examen
  /// y el feedback por topico tenga suficiente senal.
  @override
  Future<List<QuestionModel>> muestraEstratificada({
    required String categoriaCodigo,
    required int cantidad,
    List<String> excluirIds = const [],
  }) async {
    final banco = (await balotario(categoriaCodigo))
        .where((q) => !excluirIds.contains(q.id))
        .toList(growable: false);
    if (banco.length <= cantidad) return banco;

    final porTopico = <String, List<QuestionModel>>{};
    for (final q in banco) {
      porTopico.putIfAbsent(q.topicoCodigo, () => []).add(q);
    }

    final seleccion = <QuestionModel>[];
    for (final entrada in porTopico.entries) {
      final cupo = (entrada.value.length / banco.length * cantidad).round();
      final barajado = [...entrada.value]..shuffle(_random);
      seleccion.addAll(barajado.take(cupo));
    }

    // Ajuste por redondeo.
    final restantes = [...banco.where((q) => !seleccion.contains(q))]..shuffle(_random);
    while (seleccion.length < cantidad && restantes.isNotEmpty) {
      seleccion.add(restantes.removeLast());
    }

    return (seleccion.take(cantidad).toList()..shuffle(_random));
  }
}
