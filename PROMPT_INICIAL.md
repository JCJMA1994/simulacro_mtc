# Prompt de arranque

Pega esto en Claude, ChatGPT o Gemini junto con `AGENTS.md`. Si tu herramienta
soporta archivos de contexto (Claude Code, Cursor, Copilot), copia `AGENTS.md`
como `CLAUDE.md` o `.github/copilot-instructions.md` y usa solo la sección
"Petición" de abajo.

---

## Prompt completo

```
Vas a trabajar en "Simulacro MTC", una app móvil de simulacros del examen de
conocimientos del MTC (Perú) para licencias de conducir, con feedback por
tópico según la categoría de licencia.

CONTEXTO OBLIGATORIO
Lee el archivo AGENTS.md adjunto antes de responder. Es la fuente de verdad
sobre arquitectura, interfaces, convenciones y restricciones. Si algo de tu
comportamiento por defecto contradice ese archivo, gana el archivo.

STACK
- App: Flutter 3.x / Dart 3.4+, Clean Architecture por feature, BLoC
  (flutter_bloc), RxDart para transformers de eventos, Equatable para
  igualdad, dartz para Either, get_it para inyección.
- Datos: Python 3.12 con pdfplumber para parsear los PDF oficiales del MTC.
- API: FastAPI. BD: Postgres.

REGLAS DE ARQUITECTURA (no negociables)
1. Dependencia: presentation → domain ← data. domain/ no importa Flutter,
   no conoce JSON y solo depende de dartz y equatable.
2. Los repositorios devuelven Either<Failure, T> y nunca lanzan. Las
   excepciones se traducen a Failure en la implementación.
3. Los blocs no hacen I/O: solo llaman casos de uso. No importan nada de data/.
4. El bloc no crea streams de tiempo: los pide al puerto Ticker.
5. Entidades inmutables con Equatable y copyWith. Un caso de uso, una
   operación, con call().
6. Las reglas del examen (cantidad de preguntas, mínimo aprobatorio, duración)
   viven en la entidad LicenseCategory, cargada desde JSON. Nunca las
   codifiques en un widget, un bloc o un endpoint. B-IIa es la excepción del
   dominio: 35 preguntas y 30 para aprobar, cuando el resto es 40 y 35. Si
   escribes `if (codigo == 'B-IIa')` en cualquier lado, está mal.

DOMINIO
9 categorías (A-I, A-IIa, A-IIb, A-IIIa, A-IIIb, A-IIIc, B-IIa, B-IIb, B-IIc)
y 12 tópicos. Cada pregunta pertenece a un tópico: eso es lo que permite decir
"fallaste señales de tránsito" en vez de "32/40". Umbrales de dominio: >= 0.9
sólido, >= 0.7 en riesgo, resto crítico.

DISEÑO (si tocas UI)
Azul #0E4C8A acción, verde #1D7A4F acierto, rojo #B3261E error, ámbar #B87407
alerta, fondo #F5F3EE, superficie #FFFFFF, texto #1C1B19, secundario #6B6A65.
Inter, cifras tabulares en marcador y cronómetro. Botones 52 de alto, radio 12.
Durante el examen no hay verde ni rojo: el examen real no te dice si acertaste.
Copy sin exclamaciones, sin emojis, sin culpar al usuario; números siempre con
su total ("32/40", nunca "32").

RESTRICCIÓN DE DATOS
El portal del MTC desautoriza el acceso automatizado. Los PDF se descargan a
mano y se suben a sources/pdf/; el CI solo vigila la página pública y avisa si
cambió. No propongas ni escribas código para evadir eso (rotación de
user-agents, proxies, reintentos agresivos). La clave de respuestas que
extrae el parser es una hipótesis sobre el formato del PDF y no está
verificada: trátala como sospechosa.

CÓMO QUIERO QUE TRABAJES
- Código y comentarios en español, sin tildes en identificadores.
- Comentarios que expliquen por qué, no qué.
- Antes de escribir, dime en qué capa va el cambio. Si toca varias, empieza
  por el dominio.
- No agregues dependencias sin decir qué alternativa descartaste.
- Al terminar, lista los archivos que tocaste y qué quedó pendiente. Si algo
  quedó a medias, dilo; no lo escondas en un TODO.
- Si mi pedido rompe un invariante de arquitectura, no lo hagas: proponme la
  alternativa y espera mi confirmación.
- Si algo del contexto es ambiguo, pregunta antes de asumir.

PETICIÓN
[describe acá la tarea]
```

---

## Peticiones de ejemplo

Reemplaza el bloque `PETICIÓN` por una de estas.

**UI de la pantalla de examen**
```
Escribe la pantalla de rendición del simulacro: ExamPage con BlocBuilder sobre
ExamBloc, cronómetro que no repinte las opciones en cada tick (usa
context.select), barra de progreso, opciones seleccionables, botón de marcar y
navegación. Respeta el sistema visual y no muestres verde ni rojo durante el
examen. Incluye el ThemeData con los tokens de color y tipografía.
```

**Feedback histórico y muestreo ponderado**
```
Agrega el cálculo de PerfilDeDominio: agrega los últimos N intentos de una
categoría en un dominio por tópico, y úsalo para sesgar el muestreo del
siguiente simulacro hacia los tópicos débiles. Empieza por la entidad y el
caso de uso, con tests sin mocks.
```

**Migración a sqflite**
```
Migra el historial de intentos de shared_preferences a sqflite siguiendo el
esquema de db/schema.sql, incluyendo clave_estable para que el progreso
sobreviva a una renumeración del balotario. Escribe la migración de los datos
existentes. No cambies el contrato AttemptRepository.
```

**Verificar el parser**
```
Adjunto el PDF real del balotario A-I. Revisa si el parser de
tools/scrape_balotarios_mtc.py acierta con el formato: cómo vienen numeradas
las preguntas, dónde está la clave de respuestas y si hay columnas. Corrige el
parser contra el formato real y dime cuántas preguntas quedaron sin clave.
```

**Tests del bloc**
```
Escribe los tests de ExamBloc con bloc_test y FakeTicker: examen que se agota
por tiempo, reanudación después de 20 minutos fuera de la app, B-IIa con 35/30,
respuestas en blanco al finalizar. Sin Future.delayed.
```
