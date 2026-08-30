import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simulacro_mtc/features/simulacro/domain/entities/question.dart';
import 'package:simulacro_mtc/features/simulacro/domain/repositories/balotario_repository.dart';
import 'package:simulacro_mtc/features/simulacro/domain/usecases/obtener_balotario.dart';

class MockBalotarioRepository extends Mock implements BalotarioRepository {}

void main() {
  late ObtenerBalotario useCase;
  late MockBalotarioRepository mockRepository;

  setUp(() {
    mockRepository = MockBalotarioRepository();
    useCase = ObtenerBalotario(mockRepository);
  });

  const tPregunta = Question(
    id: 'A-I-0001',
    numero: 1,
    categoriaCodigo: 'A-I',
    topicoCodigo: 'SENIALES',
    enunciado: 'Enunciado de prueba',
    opciones: ['A', 'B', 'C', 'D'],
    indiceCorrecto: 0,
  );

  test('debe retornar la lista de preguntas del balotario desde el repositorio', () async {
    when(() => mockRepository.obtenerBalotario('A-I'))
        .thenAnswer((_) async => const Right([tPregunta]));

    final resultado = await useCase(const ObtenerBalotarioParams(categoriaCodigo: 'A-I'));

    expect(resultado, const Right([tPregunta]));
    verify(() => mockRepository.obtenerBalotario('A-I')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
