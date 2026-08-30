import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/exam_result.dart';
import 'package:simulacro_mtc/features/simulacro/domain/repositories/attempt_repository.dart';
import 'package:simulacro_mtc/features/simulacro/domain/usecases/obtener_historial.dart';

class MockAttemptRepository extends Mock implements AttemptRepository {}

void main() {
  late ObtenerHistorial useCase;
  late MockAttemptRepository mockRepository;

  setUp(() {
    mockRepository = MockAttemptRepository();
    useCase = ObtenerHistorial(mockRepository);
  });

  const tResultado = ExamResult(
    categoriaCodigo: 'A-I',
    correctas: 38,
    total: 40,
    minimoAprobatorio: 35,
    tiempoUsado: Duration(minutes: 25),
    porTopico: [],
    preguntasFalladasIds: ['1', '2'],
  );

  test('debe retornar el historial de intentos desde el repositorio', () async {
    when(() => mockRepository.historial('A-I'))
        .thenAnswer((_) async => const Right([tResultado]));

    final resultado = await useCase(const ObtenerHistorialParams(categoriaCodigo: 'A-I'));

    expect(resultado, const Right([tResultado]));
    verify(() => mockRepository.historial('A-I')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
