# AGENTS.md — contexto del proyecto para asistentes de IA

> Este archivo es la fuente de verdad para cualquier agente (Claude, ChatGPT,
> Gemini, Copilot) que trabaje en este repositorio. Léelo completo antes de
> escribir código. Si algo acá contradice tu intuición por defecto, gana este
> archivo.
>
> Nombres equivalentes: copia este archivo como `CLAUDE.md` y `.github/copilot-instructions.md`
> si tu herramienta busca ese nombre. El contenido es el mismo.

---

## 1. Qué es esto

App móvil de simulacros del **examen de conocimientos del MTC (Perú)** para
licencias de conducir, con **feedback por tópico según la categoría**.

Lo que la diferencia de un PDF: no dice "32/40", dice "fallaste la mitad de
señales de tránsito, ahí están los 3 puntos que te faltan". Toda decisión
técnica se justifica contra eso.

**Componentes**

| Ruta | Qué es | Stack |
|---|---|---|
| `lib/` | App Flutter | Flutter 3.x, Dart 3.4+ |
| `tools/` | Pipeline de scraping de los PDF oficiales | Python 3.12, pdfplumber |
| `api/` | API que sirve los balotarios y genera simulacros | FastAPI |
| `db/` | Esquema de la base de datos | Postgres |
| `.github/workflows/` | CI de datos | GitHub Actions |

---

## 2. Dominio: lo que no se negocia

**Nueve categorías de licencia**, cada una con su propio balotario y sus
propias reglas de examen:

| Código | Preguntas | Mínimo | Tiempo |
|---|---|---|---|
| A-I, A-IIa, A-IIb, A-IIIa, A-IIIb, A-IIIc | 40 | 35 | 40 min |
| B-IIa | **35** | **30** | 40 min |
| B-IIb, B-IIc | 40 | 35 | 40 min |

**B-IIa es la excepción y es la trampa del proyecto.** Nunca escribas
`if (codigo == 'B-IIa')`. Esas reglas viven en `LicenseCategory`, que se
carga desde `assets/balotarios/catalogo_categorias.json`. Si te encuentras
codificando 40 o 35 en un widget, un bloc o un endpoint, estás mal.

**Doce tópicos** (`SENIALES`, `CIRCULACION`, `VELOCIDAD`, `INFRACCIONES`,
`DOCUMENTOS`, `SEGURIDAD`, `MECANICA`, `AUXILIOS`, `AMBIENTE`,
`TRANSPORTE_PERSONAS`, `MERCANCIAS`, `MOTOS`). Cada categoría usa un
subconjunto. El tópico de cada pregunta es lo que hace posible el feedback:
sin él, la app no tiene razón de existir.

**Umbrales de dominio** (fijados en `TopicFeedback.nivel`, y el diseño visual
los respeta): `>= 0.9` sólido/verde, `>= 0.7` en riesgo/ámbar, resto
crítico/rojo.

---

## 3. Arquitectura

Clean Architecture por feature. Regla de dependencia: **`presentation → domain ← data`**.

```
lib/
├─ core/
│  ├─ bloc/event_transformers.dart   restartable, droppable, secuencial, debounce (RxDart)
│  ├─ error/failures.dart            sealed class Failure
│  ├─ error/exceptions.dart          CacheException, ServerException
│  ├─ network/network_info.dart      puerto de conectividad
│  ├─ time/ticker.dart               puerto de tiempo
│  └─ usecases/usecase.dart          UseCase<Type, Params>, SyncUseCase, NoParams
└─ features/simulacro/
   ├─ domain/        entidades · contratos de repositorio · casos de uso
   ├─ data/          modelos · data sources · implementaciones de repositorio
   └─ presentation/  ExamBloc · widgets
```

### Invariantes que un agente NO puede romper

1. **`domain/` no importa Flutter.** Ni `material.dart`, ni `rootBundle`, ni
   `http`. La única dependencia externa permitida es `dartz` y `equatable`.
2. **`domain/` no conoce JSON.** Nada de `fromJson` en entidades. Eso vive en
   `data/models/`, donde `XModel extends X`.
3. **Los repositorios devuelven `Either<Failure, T>`**, nunca lanzan. Las
   excepciones se atrapan en la implementación del repositorio y se traducen
   a `Failure`.
4. **Los blocs no hacen I/O.** Solo llaman casos de uso. Si un bloc importa
   algo de `data/`, está mal.
5. **El bloc no crea streams de tiempo.** Los pide a `Ticker`. Esto existe
   para que los tests no esperen 40 minutos reales.
6. **Entidades inmutables** con `Equatable` + `copyWith`. Sin setters.
7. **Un caso de uso, una operación**, con `call()`. Sin clases "Service" que
   hagan cinco cosas.

### Interfaces principales

```dart
// core/usecases/usecase.dart
abstract interface class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
abstract interface class SyncUseCase<Type, Params> {
  Either<Failure, Type> call(Params params);
}

// core/time/ticker.dart
abstract interface class Ticker {
  Stream<Duration> cuentaRegresiva(Duration total);
  DateTime ahora();
}

// domain/repositories/balotario_repository.dart
abstract interface class BalotarioRepository {
  Future<Either<Failure, List<LicenseCategory>>> obtenerCategorias();
  Future<Either<Failure, LicenseCategory>> obtenerCategoria(String codigo);
  Future<Either<Failure, List<Question>>> obtenerBalotario(String categoriaCodigo);
  Future<Either<Failure, List<Question>>> obtenerPreguntasDeSimulacro({
    required String categoriaCodigo,
    required int cantidad,
    List<String> excluirIds,
  });
}

// domain/repositories/session_repository.dart  (sesión EN CURSO, no historial)
abstract interface class SessionRepository {
  Future<Either<Failure, Unit>> guardarEnCurso(ExamSession sesion);
  Future<Either<Failure, ExamSession?>> recuperarEnCurso();
  Future<Either<Failure, Unit>> descartarEnCurso();
}

// domain/repositories/attempt_repository.dart  (historial)
abstract interface class AttemptRepository {
  Future<Either<Failure, Unit>> guardar(ExamResult resultado);
  Future<Either<Failure, List<ExamResult>>> historial(String categoriaCodigo);
  Future<Either<Failure, List<String>>> preguntasFalladas(String categoriaCodigo);
  Stream<List<ExamResult>> observarHistorial(String categoriaCodigo);
}
```

### Entidades

| Entidad | Rol |
|---|---|
| `LicenseCategory` | Categoría **con sus reglas de examen** (preguntas, mínimo, duración, tópicos) |
| `Question` | Pregunta con opciones, índice correcto, tópico, explicación, imagen |
| `ExamAnswer` | Respuesta del usuario a una pregunta |
| `ExamSession` | Estado inmutable del simulacro en curso |
| `TopicFeedback` | Dominio por tópico (`correctas/total`, `nivel`) |
| `ExamResult` | Resultado calificado con desglose y `puntoDebil` |

### Casos de uso

`ObtenerCategorias` · `IniciarSimulacro` · `ReanudarSimulacro` ·
`AutoguardarSesion` · `CalcularFeedback` (síncrono, puro) · `GuardarIntento`

### RxDart: cuándo usar cada transformer

| Situación | Transformer | Por qué |
|---|---|---|
| Iniciar/reanudar simulacro | `restartable()` (`switchMap`) | cambiar de categoría mata el intento anterior |
| Siguiente / anterior / saltar | `droppable()` (`exhaustMap`) | doble tap no salta dos preguntas |
| Responder, marcar, tick | `secuencial()` (`asyncExpand`) | preserva el orden |
| Autoguardado | `debounce(700ms)` | no escribir en disco en cada tick |
| Historial de intentos | `BehaviorSubject` | la pantalla recibe el último valor al suscribirse |

---

## 4. Diseño (si tocas UI)

- Color: azul `#0E4C8A` acción · verde `#1D7A4F` acierto · rojo `#B3261E` error ·
  ámbar `#B87407` alerta · fondo `#F5F3EE` · superficie `#FFFFFF` ·
  texto `#1C1B19` · secundario `#6B6A65` · borde `#E0DDD4`.
- Tipografía Inter. Marcador y cronómetro con **cifras tabulares**.
- Botones: alto 52, radio 12, texto 16/500. Una acción principal por pantalla.
- **Durante el examen no hay verde ni rojo.** El examen real no te dice si
  acertaste. Esos colores aparecen recién en resultado y repaso.
- El cronómetro pasa a ámbar en los últimos 5 minutos, sin parpadeos ni
  vibración.
- Copy: sin signos de exclamación, sin emojis, sin culpar al usuario.
  "Te faltaron 3 respuestas", no "¡Desaprobado! 😔". Números siempre con su
  total: `32/40`, nunca `32`.

---

## 5. Datos: scraping y API

**Pipeline** (`fetch → extract → parse → classify → validate → diff → emit`):

```bash
python tools/scrape_balotarios_mtc.py --local sources/pdf --out assets/balotarios --debug
python tools/pipeline/extraer_imagenes.py sources/pdf/A-I.pdf --out assets/senales/A-I
python tools/pipeline/validar.py assets/balotarios --strict
python tools/pipeline/diff.py assets/balotarios --salida diff.md
```

**Regla legal y operativa: no automatizar la descarga desde
`portal.mtc.gob.pe`.** Ese portal desautoriza el acceso automatizado. Los PDF
se descargan a mano (o se piden por acceso a la información pública) y se
suben a `sources/pdf/<CODIGO>.pdf`. El CI solo vigila la página pública de
gob.pe y abre un issue si cambió. **Un agente no debe proponer ni escribir
código que evada esa restricción** (rotación de user-agents, proxies,
reintentos agresivos). Si te piden eso, explica la alternativa.

**`clave_estable`** = `sha1(categoria + enunciado normalizado)`. Es lo que
hace que el progreso del usuario sobreviva a una renumeración del balotario.
Nunca uses el número de pregunta como identificador persistente.

**API** (`api/app/main.py`): `GET /v1/version` (manifiesto de hashes),
`GET /v1/categorias`, `GET /v1/categorias/{c}/balotario` (ETag + 304),
`POST /v1/categorias/{c}/simulacros` (muestra ponderada por dominio del
usuario). La app es offline-first: arranca con los assets empaquetados y solo
va a la red cuando el manifiesto dice que algo cambió.

**Muestreo:** proporcional por tópico por defecto; ponderado hacia los tópicos
débiles cuando el cliente envía su dominio. Nunca uniforme al azar: un tópico
con pocas preguntas casi no aparecería y su barra de feedback sería ruido.

---

## 6. Convenciones de código

- **Idioma:** código y comentarios en español (`iniciarSimulacro`,
  `preguntasFalladas`). Tipos del framework en inglés (`Failure`, `UseCase`).
  Sin tildes en identificadores.
- Clases `final class` o `sealed class` por defecto. `abstract interface class`
  para contratos.
- Comentarios: explican **por qué**, no qué. Si el comentario repite el nombre
  del método, bórralo.
- Archivos en `snake_case.dart`; un tipo público por archivo.
- Sin `print` en `lib/`. Sin `late` mutable. Sin `!` salvo tras un chequeo
  visible en la misma función.
- Python: type hints, `from __future__ import annotations`, `pathlib`, sin
  dependencias nuevas sin justificar.

---

## 7. Tests

- **Dominio primero.** `CalcularFeedback` se testea sin mocks: es puro.
- Blocs con `bloc_test` + `FakeTicker` (en `test/.../fake_ticker.dart`).
  Nunca `await Future.delayed` en un test.
- Mocks con `mocktail`, solo de interfaces del dominio.
- Un test por regla de negocio, no por método. Casos que importan: B-IIa con
  35/30, tiempo agotado a mitad de examen, reanudación después de 20 minutos
  fuera de la app, balotario incompleto, respuestas en blanco.

---

## 8. Cómo trabajar en este repo

**Antes de escribir código:**
1. Identifica en qué capa va el cambio. Si toca varias, escribe el dominio primero.
2. Si necesitas un dato nuevo, empieza por la entidad, luego el contrato de
   repositorio, luego la implementación, luego el bloc, luego la UI.
3. No agregues dependencias sin decir por qué y qué alternativa descartaste.

**Al entregar:**
- Di qué archivos tocaste y por qué.
- Si dejaste algo a medias, dilo explícitamente. No lo escondas en un TODO.
- Si el cambio rompe un invariante de la sección 3, no lo hagas: propón la
  alternativa y espera confirmación.

**Cosas que suelen salir mal y hay que vigilar:**
- Codificar 40/35 en vez de leerlo de `LicenseCategory`.
- Meter `fromJson` en una entidad del dominio.
- Emitir estado desde el bloc dentro de un `listen` en vez de agregar un evento.
- Repintar toda la pantalla en cada tick del cronómetro (usa `context.select`).
- Asumir que la clave de respuestas del PDF ya está verificada. **No lo está.**
  El parser de `tools/` es una hipótesis sobre el formato del PDF y hay que
  validarla con `--debug` contra el documento real.

---

## 9. Estado actual

**Hecho:** entidades y casos de uso del dominio · `ExamBloc` con Ticker,
autoguardado y reanudación · data sources locales (assets, prefs) · cliente
HTTP de la API · DI con get_it · catálogo de las 9 categorías · scraper y
pipeline de validación/diff/imágenes · API FastAPI · esquema Postgres ·
workflow de CI · sistema visual y pantallas principales.

**Pendiente:** widgets de Flutter (no hay UI escrita todavía, solo mockups) ·
poblar `balotario_*.json` con PDF reales y **verificar la clave de
respuestas** · migrar de `shared_preferences` a `sqflite` · explicaciones por
pregunta · cortar la feature en `catalogo` / `simulacro` / `estudio` /
`progreso` cuando crezca.
