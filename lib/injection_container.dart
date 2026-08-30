import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/time/ticker.dart';
import 'features/simulacro/data/datasources/attempt_local_data_source.dart';
import 'features/simulacro/data/datasources/balotario_local_data_source.dart';
import 'features/simulacro/data/datasources/balotario_remote_data_source.dart';
import 'features/simulacro/data/datasources/session_local_data_source.dart';
import 'features/simulacro/data/repositories/attempt_repository_impl.dart';
import 'features/simulacro/data/repositories/balotario_repository_impl.dart';
import 'features/simulacro/data/repositories/session_repository_impl.dart';
import 'features/simulacro/domain/repositories/attempt_repository.dart';
import 'features/simulacro/domain/repositories/balotario_repository.dart';
import 'features/simulacro/domain/repositories/session_repository.dart';
import 'features/simulacro/domain/usecases/autoguardar_sesion.dart';
import 'features/simulacro/domain/usecases/calcular_feedback.dart';
import 'features/simulacro/domain/usecases/guardar_intento.dart';
import 'features/simulacro/domain/usecases/iniciar_simulacro.dart';
import 'features/simulacro/domain/usecases/obtener_balotario.dart';
import 'features/simulacro/domain/usecases/obtener_categorias.dart';
import 'features/simulacro/domain/usecases/obtener_historial.dart';
import 'features/simulacro/domain/usecases/reanudar_simulacro.dart';
import 'features/simulacro/presentation/bloc/exam/exam_bloc.dart';

final sl = GetIt.instance;

const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

Future<void> init() async {
  if (sl.isRegistered<SharedPreferences>()) {
    return;
  }

  // Externo
  sl.registerSingletonAsync<SharedPreferences>(SharedPreferences.getInstance);
  await sl.isReady<SharedPreferences>();
  sl
    ..registerLazySingleton(http.Client.new)
    ..registerLazySingleton<Ticker>(RelojTicker.new)

    // Data sources
    ..registerLazySingleton<BalotarioLocalDataSource>(BalotarioAssetDataSource.new)
    ..registerLazySingleton<BalotarioRemoteDataSource>(
      () => BalotarioHttpDataSource(cliente: sl(), baseUrl: _baseUrl),
    )
    ..registerLazySingleton<AttemptLocalDataSource>(() => AttemptPrefsDataSource(sl()))
    ..registerLazySingleton<SessionLocalDataSource>(() => SessionPrefsDataSource(sl()))

    // Repositorios
    ..registerLazySingleton<BalotarioRepository>(() => BalotarioRepositoryImpl(sl()))
    ..registerLazySingleton<AttemptRepository>(() => AttemptRepositoryImpl(sl()))
    ..registerLazySingleton<SessionRepository>(() => SessionRepositoryImpl(sl(), sl()))

    // Casos de uso
    ..registerLazySingleton(() => ObtenerCategorias(sl()))
    ..registerLazySingleton(() => IniciarSimulacro(sl()))
    ..registerLazySingleton(() => ReanudarSimulacro(sl(), sl()))
    ..registerLazySingleton(() => AutoguardarSesion(sl()))
    ..registerLazySingleton(() => const CalcularFeedback())
    ..registerLazySingleton(() => GuardarIntento(sl()))
    ..registerLazySingleton(() => ObtenerBalotario(sl()))
    ..registerLazySingleton(() => ObtenerHistorial(sl()))

    // Blocs
    ..registerFactory(
      () => ExamBloc(
        iniciarSimulacro: sl(),
        reanudarSimulacro: sl(),
        autoguardarSesion: sl(),
        calcularFeedback: sl(),
        guardarIntento: sl(),
        sessionRepository: sl(),
        ticker: sl(),
      ),
    );
}
