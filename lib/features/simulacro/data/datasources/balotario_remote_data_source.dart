import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/question_model.dart';

/// Cliente de la API de balotarios (api/app/main.py).
///
/// Offline-first: la app arranca con los assets empaquetados y solo consulta
/// la red cuando el manifiesto de version dice que algo cambio.
abstract interface class BalotarioRemoteDataSource {
  Future<Map<String, String>> versiones();
  Future<List<QuestionModel>> balotario(String categoriaCodigo, {String? etag});
}

final class BalotarioHttpDataSource implements BalotarioRemoteDataSource {
  const BalotarioHttpDataSource({required http.Client cliente, required String baseUrl})
      : _cliente = cliente,
        _baseUrl = baseUrl;

  final http.Client _cliente;
  final String _baseUrl;

  @override
  Future<Map<String, String>> versiones() async {
    final resp = await _cliente.get(Uri.parse('$_baseUrl/v1/version'));
    if (resp.statusCode != 200) throw ServerException('version: ${resp.statusCode}');
    final j = jsonDecode(resp.body) as Map<String, dynamic>;
    return {
      for (final e in (j['balotarios'] as Map<String, dynamic>).entries)
        e.key: (e.value as Map<String, dynamic>)['hash'] as String,
    };
  }

  @override
  Future<List<QuestionModel>> balotario(String categoriaCodigo, {String? etag}) async {
    final resp = await _cliente.get(
      Uri.parse('$_baseUrl/v1/categorias/$categoriaCodigo/balotario'),
      headers: {if (etag != null) 'If-None-Match': etag},
    );
    if (resp.statusCode == 304) return const [];
    if (resp.statusCode != 200) throw ServerException('balotario: ${resp.statusCode}');

    final j = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return [
      for (final p in j['preguntas'] as List<dynamic>)
        QuestionModel.fromJson(p as Map<String, dynamic>),
    ];
  }
}
