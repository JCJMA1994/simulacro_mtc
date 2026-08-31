# Simulacro MTC — Examen de Conocimientos Oficial

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-1D7A4F)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![FastAPI](https://img.shields.io/badge/API-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?logo=python)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Aplicación móvil de alto rendimiento y arquitectura limpia para la preparación y simulación del **Examen de Conocimientos de Reglas de Tránsito del MTC (Perú)** con **diagnóstico y feedback granular por tópico** según la categoría de licencia postulada.

A diferencia de un visor tradicional o un test genérico, el sistema no solo reporta una nota global (ej. `32/40`), sino que desglosa el rendimiento por áreas temáticas (*"Fallaste 3 preguntas en Señales de Tránsito: ahí están los puntos que te faltan para aprobar"*).

---

## 🗺️ Arquitectura del Sistema

El ecosistema está construido bajo principios de **Clean Architecture** (por features) en el cliente móvil, complementado por un backend en FastAPI para sincronización de versiones y un pipeline automatizado de ingestión de balotarios oficiales.

```
       ┌────────────────────────────────────────────────────────┐
       │                   PRESENTATION (UI)                    │
       │           Widgets · Pages · ExamBloc · Themes          │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │                     DOMAIN LAYER                       │
       │    Entities · Use Cases (Puros) · Repository Contracts │
       │               (0 dependencias de Flutter)              │
       └───────────────────────────▲────────────────────────────┘
                                   │
       ┌───────────────────────────┴────────────────────────────┐
       │                      DATA LAYER                        │
       │   Models (JSON) · Data Sources · Repository Impls      │
       │           Local Assets · SQLite / SharedPreferences   │
       └────────────────────────────────────────────────────────┘
```

### 📊 Diagrama Interactivo de Arquitectura

El proyecto incluye un diagrama interactivo completo generado con **Archify**. Podés abrirlo en tu navegador para explorar las capas, flujos de datos y conexiones del sistema:

👉 **[Ver Diagrama Interactivo de Arquitectura (HTML)](simulacro-mtc-architecture.html)**  
*(Especificación formal en [simulacro_mtc.architecture.json](simulacro_mtc.architecture.json))*

---

## 📋 Reglas de Dominio y Balotarios Oficiales

Fuente oficial: **Ministerio de Transportes y Comunicaciones (MTC - Perú)**. El sistema soporta las **9 categorías de licencia**, cada una con sus propios parámetros de evaluación:

| Código | Clase y Categoría | Tipo de Vehículos | Preguntas | Mínimo Aprobatorio | Tiempo Límite |
|---|---|---|---|---|---|
| **A-I** | Particular Clase A | Autos, sedanes, SUVs, camionetas particulares (M1, M2, N1) | 40 | 35 | 40 min |
| **A-IIa** | Profesional Clase A | Taxi, movilidad escolar, servicio de pasajeros | 40 | 35 | 40 min |
| **A-IIb** | Profesional Clase A | Microbuses (M2, M3), camiones medianos (N2) | 40 | 35 | 40 min |
| **A-IIIa** | Profesional Clase A | Ómnibus de transporte interprovincial y camiones pesados | 40 | 35 | 40 min |
| **A-IIIb** | Profesional Clase A | Combinaciones especiales, remolques y semirremolques | 40 | 35 | 40 min |
| **A-IIIc** | Profesional Clase A | Toda la Clase A + transporte de mercancías peligrosas | 40 | 35 | 40 min |
| **B-IIa** | Clase B (Vehículos menores) | Motofurgones y vehículos menores de carga | **35** | **30** | 40 min |
| **B-IIb** | Clase B (Vehículos menores) | Motocicletas particulares | 40 | 35 | 40 min |
| **B-IIc** | Clase B (Vehículos menores) | Mototaxis y trimotos de pasajeros | 40 | 35 | 40 min |

> ⚠️ **Invariante Crítico de Negocio:** La categoría **B-IIa** es la única con 35 preguntas y mínimo 30. Las reglas de examen residen en la entidad `LicenseCategory` (`assets/balotarios/catalogo_categorias.json`). Nunca se codifican constantes mágicas como `40` o `35` en widgets ni BLoCs.

### Tópicos Evaluados y Niveles de Dominio
Cada pregunta pertenece a uno de los **12 tópicos oficiales**:
`SENIALES`, `CIRCULACION`, `VELOCIDAD`, `INFRACCIONES`, `DOCUMENTOS`, `SEGURIDAD`, `MECANICA`, `AUXILIOS`, `AMBIENTE`, `TRANSPORTE_PERSONAS`, `MERCANCIAS`, `MOTOS`.

Los umbrales de diagnóstico están fijados en el dominio (`TopicFeedback.nivel`):
- 🟢 **Sólido / Aprobado:** $\ge 90\%$ de aciertos en el tópico.
- 🟡 **En Riesgo / Alerta:** $\ge 70\%$ y $< 90\%$.
- 🔴 **Crítico / Deficiente:** $< 70\%$ (punto débil a reforzar).

---

## 🛠️ Requisitos Previos del Sistema

Asegúrate de contar con el siguiente software instalado en tu entorno de desarrollo:

- **Flutter SDK:** `>= 3.22.0` (Dart `>= 3.4.0 < 4.0.0`)
- **Android SDK:** API Level 34+ / Android Studio (para desarrollo Android)
- **Xcode:** 15+ (para desarrollo iOS / macOS)
- **Python:** `>= 3.12` (para el scraper y la API)
- **Node.js:** `>= 18` (para tooling de arquitectura y diagramación)
- **PostgreSQL:** `>= 15` (opcional, para persistencia del backend FastAPI)

---

## 🚀 Instalación y Puesta en Marcha

### 1. Clonar el Repositorio

```bash
git clone https://github.com/JCJMA1994/simulacro_mtc.git
cd simulacro_mtc
```

### 2. Configurar la App Móvil (Flutter)

```bash
# Obtener dependencias de Flutter
flutter pub get

# Verificar que el entorno esté listo
flutter doctor
```

### 3. Configurar el Entorno Python (Pipeline & API)

```bash
# Crear y activar entorno virtual
python -m venv .venv

# En Windows (PowerShell):
.venv\Scripts\Activate.ps1
# En macOS/Linux:
source .venv/bin/activate

# Instalar dependencias del scraper y pipeline
pip install -r tools/requirements.txt

# Instalar dependencias de la API
pip install -r api/requirements.txt
```

---

## 📱 Compilación y Ejecución

### App Móvil Flutter

#### Modo Desarrollo
```bash
# Ejecutar en emulador o dispositivo conectado
flutter run
```

#### Compilación de Producción

* **Android APK (Release):**
  ```bash
  flutter build apk --release
  ```
  *(Salida: `build/app/outputs/flutter-apk/app-release.apk`)*

* **Android App Bundle (Google Play Store):**
  ```bash
  flutter build appbundle --release
  ```
  *(Salida: `build/app/outputs/bundle/release/app-release.aab`)*

* **iOS (Release):**
  ```bash
  flutter build ios --release --no-codesign
  ```

* **Web (Release):**
  ```bash
  flutter build web --release
  ```

---

### Pipeline de Ingestión de Balotarios (Python)

El pipeline procesa los PDFs oficiales del MTC y genera los assets JSON normalizados con hashes estables (`sha1` del enunciado) para soportar versionado sin perder el historial del postulante.

```bash
# 1. Extraer y estructurar preguntas desde PDFs locales
python tools/scrape_balotarios_mtc.py --local sources/pdf --out assets/balotarios --debug

# 2. Extraer imágenes de señales embebidas en los PDF
python tools/pipeline/extraer_imagenes.py sources/pdf/A-I.pdf --out assets/senales/A-I

# 3. Validar consistencia e integridad de los balotarios generados
python tools/pipeline/validar.py assets/balotarios --strict

# 4. Generar reporte de diferencias frente a versiones anteriores
python tools/pipeline/diff.py assets/balotarios --salida diff.md
```

> ⚖️ **Aviso Legal y Operativo:** El portal del MTC bloquea el scraping no supervisado. Los PDFs se descargan manualmente a `sources/pdf/<CATEGORIA>.pdf`. El CI supervisa cambios en la página informativa de gob.pe.

---

### Backend API (FastAPI)

Provee endpoints para verificación de versiones (`GET /v1/version`), descarga con ETag (`GET /v1/categorias/{c}/balotario`) y generación de simulacros ponderados hacia los puntos débiles del usuario (`POST /v1/categorias/{c}/simulacros`).

```bash
# Iniciar servidor FastAPI en modo desarrollo
cd api
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

### Diagramas de Arquitectura (Archify)

Para compilar, validar o regenerar los diagramas interactivos del sistema:

```bash
# Validar la especificación de arquitectura con perfil showcase
node .agents/skills/archify/bin/archify.mjs validate architecture simulacro_mtc.architecture.json --quality showcase --json

# Compilar y entregar el visualizador HTML interactivo
node .agents/skills/archify/bin/archify.mjs deliver architecture simulacro_mtc.architecture.json simulacro-mtc-architecture.html --quality showcase --json
```

---

## 🧪 Pruebas Automatizadas y Calidad

El proyecto aplica pruebas unitarias rigurosas sobre el dominio y los manejadores de estado:

```bash
# Ejecutar todas las pruebas unitarias de Flutter
flutter test

# Análisis estático de código y reglas de linter
flutter analyze
```

### Principios de Testing
- **Dominio Puro:** `CalcularFeedback` y los casos de uso de negocio se testean de forma síncrona y sin mocks.
- **BLoCs con `FakeTicker`:** Los eventos de tiempo y el cronómetro de 40 minutos se prueban de forma determinista sin esperas asíncronas (`await Future.delayed`).
- **Mocks Aislados:** Mocks mediante `mocktail` limitados estrictamente a las interfaces del dominio (`domain/repositories/`).

---

## 🎨 Sistema de Diseño y UI/UX

Diseñado para simular con fidelidad la experiencia del examen real mientras provee una interfaz limpia, moderna y accesible:

- **Paleta de Colores Oficial:**
  - `AppColors.primary`: `#0E4C8A` (Azul institucional MTC)
  - `AppColors.success`: `#1D7A4F` (Verde acierto)
  - `AppColors.error`: `#B3261E` (Rojo error)
  - `AppColors.warning`: `#B87407` (Ámbar alerta)
  - `AppColors.background`: `#F7F6F2` (Fondo cálido neutro)
  - `AppColors.surface`: `#FFFFFF` (Superficie limpia)
- **Tipografía:** `Inter` con soporte de **cifras tabulares** (`fontFeatures: [FontFeature.tabularFigures()]`) para evitar saltos visuales en el cronómetro y el marcador.
- **Invariante Visual en Examen:** Durante la simulación en curso no se revelan colores verde o rojo. El feedback se presenta únicamente en las vistas de **Resultado** y **Repaso**.

---

## 📂 Estructura del Repositorio

```
simulacro_mtc/
├── .agents/                    # Skills y herramientas de agentes IA (archify)
├── .github/workflows/          # CI/CD (validación de balotarios y linters)
├── api/                        # Backend REST con FastAPI
│   ├── app/                    # Endpoints, esquemas y lógica de muestreo
│   └── requirements.txt
├── assets/                     # Recursos empaquetados offline-first
│   ├── balotarios/             # JSONs estructurados por categoría
│   └── senales/                # Imágenes de señales de tránsito
├── db/                         # Esquema relacional para PostgreSQL
│   └── schema.sql
├── lib/                        # Código fuente de la aplicación Flutter
│   ├── core/                   # Bloc transformers, errores, usecases, ticker, theme
│   └── features/
│       ├── balotario/          # Modo estudio, flashcards y visualizador
│       ├── catalogo/           # Selección de categoría y reglas
│       └── simulacro/          # Examen en curso, feedback y resultados
│           ├── data/           # DataSources, modelos y repositorios
│           ├── domain/         # Entidades, contratos de repositorio y usecases
│           └── presentation/   # ExamBloc, pantallas y widgets
├── sources/                    # PDFs oficiales del MTC (fuente original)
├── test/                       # Suite de pruebas unitarias y de integración
├── tools/                      # Pipeline de scraping, extracción y validación
│   ├── pipeline/               # Scripts de diff, imágenes y validación estricta
│   └── scrape_balotarios_mtc.py
├── simulacro_mtc.architecture.json # Especificación formal de arquitectura
├── simulacro-mtc-architecture.html # Diagrama interactivo de arquitectura
└── pubspec.yaml                # Manifiesto de dependencias de Flutter
```

---

## 📄 Licencia

Este proyecto se distribuye bajo la licencia **MIT**. Consulta el archivo `LICENSE` para más detalles.
