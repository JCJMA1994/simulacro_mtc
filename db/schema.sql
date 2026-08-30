-- Postgres. Dos dominios separados a proposito:
--   contenido/  lo que publica el MTC, versionado e inmutable
--   progreso/   lo que hace cada usuario, mutable
-- Mezclarlos es lo que hace imposible actualizar el balotario sin romper el
-- historial de la gente.

-- ============================================================ contenido

CREATE TABLE balotario_version (
  id              BIGSERIAL PRIMARY KEY,
  categoria       TEXT        NOT NULL,
  hash_pdf        TEXT        NOT NULL,
  url_origen      TEXT        NOT NULL,
  resolucion      TEXT,                       -- RD que lo aprueba
  descargado_en   TIMESTAMPTZ NOT NULL,
  publicado_en    TIMESTAMPTZ,                -- NULL = aun en revision
  total_preguntas INT         NOT NULL,
  UNIQUE (categoria, hash_pdf)
);

CREATE TABLE categoria (
  codigo              TEXT PRIMARY KEY,       -- A-I, A-IIa, ... B-IIc
  nombre              TEXT NOT NULL,
  clase               TEXT NOT NULL,
  vehiculos           TEXT NOT NULL,
  es_profesional      BOOLEAN NOT NULL,
  preguntas_examen    INT  NOT NULL,
  minimo_aprobatorio  INT  NOT NULL,
  duracion_minutos    INT  NOT NULL,
  CHECK (minimo_aprobatorio <= preguntas_examen)
);

CREATE TABLE topico (
  codigo TEXT PRIMARY KEY,
  nombre TEXT NOT NULL
);

CREATE TABLE categoria_topico (
  categoria_codigo TEXT REFERENCES categoria(codigo) ON DELETE CASCADE,
  topico_codigo    TEXT REFERENCES topico(codigo)    ON DELETE RESTRICT,
  PRIMARY KEY (categoria_codigo, topico_codigo)
);

CREATE TABLE pregunta (
  id                BIGSERIAL PRIMARY KEY,
  version_id        BIGINT REFERENCES balotario_version(id) ON DELETE CASCADE,
  clave_estable     TEXT NOT NULL,            -- sha1(categoria + enunciado normalizado)
  numero            INT  NOT NULL,
  categoria_codigo  TEXT REFERENCES categoria(codigo),
  topico_codigo     TEXT REFERENCES topico(codigo),
  topico_confianza  REAL,                     -- del clasificador; < 0.6 = revisar a mano
  topico_manual     BOOLEAN NOT NULL DEFAULT FALSE,
  enunciado         TEXT NOT NULL,
  explicacion       TEXT,
  imagen_url        TEXT,
  UNIQUE (version_id, numero)
);

-- clave_estable es lo que sobrevive a un re-scrape: si el MTC renumera,
-- el progreso del usuario sigue apuntando a la misma pregunta.
CREATE INDEX idx_pregunta_clave  ON pregunta (clave_estable);
CREATE INDEX idx_pregunta_topico ON pregunta (categoria_codigo, topico_codigo);

CREATE TABLE opcion (
  id          BIGSERIAL PRIMARY KEY,
  pregunta_id BIGINT REFERENCES pregunta(id) ON DELETE CASCADE,
  orden       SMALLINT NOT NULL,              -- 0..3
  texto       TEXT     NOT NULL,
  es_correcta BOOLEAN  NOT NULL,
  UNIQUE (pregunta_id, orden)
);

-- Exactamente una correcta por pregunta.
CREATE UNIQUE INDEX idx_una_correcta
  ON opcion (pregunta_id) WHERE es_correcta;

-- ============================================================= progreso

CREATE TABLE usuario (
  id          UUID PRIMARY KEY,
  creado_en   TIMESTAMPTZ NOT NULL DEFAULT now(),
  categoria_codigo TEXT REFERENCES categoria(codigo)
);

CREATE TABLE intento (
  id                 UUID PRIMARY KEY,
  usuario_id         UUID REFERENCES usuario(id) ON DELETE CASCADE,
  categoria_codigo   TEXT NOT NULL,
  version_id         BIGINT REFERENCES balotario_version(id),
  correctas          INT NOT NULL,
  total              INT NOT NULL,
  minimo_aprobatorio INT NOT NULL,
  segundos_usados    INT NOT NULL,
  aprobado           BOOLEAN GENERATED ALWAYS AS (correctas >= minimo_aprobatorio) STORED,
  finalizado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_intento_usuario ON intento (usuario_id, categoria_codigo, finalizado_en DESC);

CREATE TABLE respuesta (
  intento_id      UUID   REFERENCES intento(id) ON DELETE CASCADE,
  clave_estable   TEXT   NOT NULL,
  topico_codigo   TEXT   NOT NULL,
  opcion_elegida  SMALLINT,                   -- NULL = quedo en blanco
  es_correcta     BOOLEAN NOT NULL,
  segundos        INT,
  PRIMARY KEY (intento_id, clave_estable)
);

-- Dominio por topico: alimenta el feedback y el muestreo ponderado.
CREATE VIEW dominio_por_topico AS
SELECT i.usuario_id,
       i.categoria_codigo,
       r.topico_codigo,
       COUNT(*)                                   AS respondidas,
       COUNT(*) FILTER (WHERE r.es_correcta)      AS correctas,
       COUNT(*) FILTER (WHERE r.es_correcta)::REAL / NULLIF(COUNT(*), 0) AS dominio
FROM intento i
JOIN respuesta r ON r.intento_id = i.id
GROUP BY i.usuario_id, i.categoria_codigo, r.topico_codigo;
