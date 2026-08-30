class CacheException implements Exception {
  const CacheException([this.mensaje = '']);
  final String mensaje;
}

class ServerException implements Exception {
  const ServerException([this.mensaje = '']);
  final String mensaje;
}
