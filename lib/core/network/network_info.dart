/// Puerto de red. La capa de datos pregunta por conectividad a traves de esto,
/// nunca a un plugin concreto: asi el repositorio se testea sin dispositivo.
abstract interface class NetworkInfo {
  Future<bool> get hayConexion;
}
