# Simulacro MTC — examen de conocimientos por categoría

App de simulacro del examen de reglas de tránsito del MTC (Perú) con feedback
por tópico según la categoría de licencia. Flutter + Clean Architecture +
BLoC + RxDart + Equatable.

## 1. Balotarios oficiales

Fuente: MTC — *Examen de conocimientos para postulantes a licencias de conducir*
(gob.pe, publicación 1928110). Hay **9 balotarios**, uno por categoría.

| Código | Clase / cat. | Vehículos | Preguntas | Mínimo | Tiempo |
|---|---|---|---|---|---|
| A-I | A · I | M1, M2, N1 particular | 40 | 35 | 40 min |
| A-IIa | A · II-A | Taxi / transporte de personas | 40 | 35 | 40 min |
| A-IIb | A · II-B | M2, M3, N2 | 40 | 35 | 40 min |
| A-IIIa | A · III-A | Buses y camiones pesados | 40 | 35 | 40 min |
| A-IIIb | A · III-B | Combinaciones y remolques | 40 | 35 | 40 min |
| A-IIIc | A · III-C | Toda la clase A + mercancías peligrosas | 40 | 35 | 40 min |
| B-IIa | B · II-A | Vehículos menores de carga | 35 | 30 | 40 min |
| B-IIb | B · II-B | Motocicletas | 40 | 35 | 40 min |
| B-IIc | B · II-C | Mototaxis y trimotos | 40 | 35 | 40 min |

Los datos y las URLs de cada PDF están en
`assets/balotarios/catalogo_categorias.json`. Verifica siempre contra la
fuente oficial antes de publicar: las cifras cambian por resolución directoral.

Nota Lima: desde el 22/04/2026 el examen de clase A en Lima Metropolitana lo
administra la MML (RM 040-2026-MTC/01.02); el balotario sigue siendo el del MTC.

## 2. Scraper

```bash
pip install requests pdfplumber
python tools/scrape_balotarios_mtc.py --out assets/balotarios --debug
```

Genera `balotario_<CODIGO>.json` con esta forma:

```json
{
  "id": "A-I-0001",
  "numero": 1,
  "categoria": "A-I",
  "topico": "VELOCIDAD",
  "enunciado": "...",
  "opciones": ["...", "...", "...", "..."],
  "respuesta_correcta": 1,
  "explicacion": "",
  "imagen": null
}
```

`portal.mtc.gob.pe` bloquea clientes automatizados. Si la descarga falla,
baja los PDF a mano desde la página de gob.pe y corre el script con
`--local <carpeta>` (nombra cada archivo `A-I.pdf`, `A-IIa.pdf`, …).

El campo `topico` lo asigna un clasificador por reglas (`REGLAS_TOPICO`). Es lo
que hace posible el feedback: sin él, el resultado solo puede decir "32/40".
Revisa la clasificación con `--debug` y corrige las reglas para tu banco.

## 3. Para agentes de IA

Antes de pedirle código a Claude, ChatGPT o Gemini, dale `AGENTS.md`
(duplicado como `CLAUDE.md`). Contiene arquitectura, interfaces, invariantes,
tokens de diseño y las restricciones de datos. `PROMPT_INICIAL.md` trae el
prompt listo para pegar con peticiones de ejemplo.

## 4. Arquitectura

```
lib/
├─ core/
│  ├─ bloc/event_transformers.dart   RxDart: restartable, droppable, debounce
│  ├─ error/                         Failure sellada + excepciones
│  └─ usecases/usecase.dart          UseCase<Type, Params>
└─ features/simulacro/
   ├─ domain/          entidades, contratos de repositorio, casos de uso  (0 deps de Flutter)
   ├─ data/            modelos JSON, data sources, implementaciones
   └─ presentation/    ExamBloc + widgets
```

Regla de dependencia: `presentation → domain ← data`. El dominio no importa
Flutter, `dartz` es la única dependencia externa que cruza hacia adentro.

**Decisiones que importan**

- `LicenseCategory` carga sus propias reglas (`preguntasPorExamen`,
  `minimoAprobatorio`, `duracion`). Nada de `if (codigo == 'B-IIa')` regado por
  la UI: B-IIa se rinde con 35/30 y eso vive en el dato, no en el widget.
- `CalcularFeedback` es un `SyncUseCase` puro. La calificación y el desglose
  por tópico se testean sin mocks, sin IO, sin `WidgetTester`.
- `muestraEstratificada` reparte las 40 preguntas proporcionalmente entre los
  tópicos del banco. Si el muestreo fuera uniforme al azar, un tópico con pocas
  preguntas casi no aparecería y su barra de feedback sería ruido.
- Entidades inmutables con `Equatable` + `copyWith`. `ExamState` re-emite solo
  cuando algo cambió de verdad, así el `BlocBuilder` no repinta cada segundo.

**Dónde entra RxDart**

| Uso | Operador | Por qué |
|---|---|---|
| Iniciar simulacro, tick de reloj | `switchMap` (restartable) | cambiar de categoría mata el intento anterior |
| Siguiente / anterior | `exhaustMap` (droppable) | un doble tap no salta dos preguntas |
| Responder, marcar | `asyncExpand` (secuencial) | preserva el orden de las respuestas |
| Buscador del balotario | `debounceTime` + `switchMap` | una consulta por ráfaga de tecleo |
| Historial de intentos | `BehaviorSubject` | la pantalla de progreso recibe el último valor al suscribirse |

El cronómetro es un `Stream.periodic` con `takeWhile`, cancelado en `close()`.
No hay `Timer` suelto que sobreviva al bloc.

## 5. API, BD y CI

- `api/app/main.py` — FastAPI: manifiesto de versiones con hash, balotario con
  ETag/304 y generación de simulacros ponderada por el dominio del usuario.
- `db/schema.sql` — Postgres, con contenido versionado separado del progreso
  del usuario y `clave_estable` como bisagra entre ambos.
- `.github/workflows/balotarios.yml` — vigila la publicación oficial y avisa
  por issue; el pipeline corre sobre los PDF que se suben a `sources/pdf/`.

## 6. Pendientes para producción

- Poblar `balotario_*.json` con el scraper y revisar la clave de respuestas.
- Migrar de `shared_preferences` a `sqflite` cuando el historial crezca.
- Imágenes de señales: el balotario las trae embebidas; extraerlas del PDF y
  referenciarlas en `imagen`.
- Explicaciones por pregunta (campo `explicacion`), que es lo que convierte el
  feedback en estudio y no solo en una nota.
