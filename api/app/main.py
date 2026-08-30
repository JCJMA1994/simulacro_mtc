"""
API de balotarios MTC.

Sirve el JSON que produce el pipeline de scraping y genera simulacros del lado
del servidor. Disenada para una app offline-first: el cliente descarga el
balotario una vez, lo cachea y solo vuelve cuando cambia la version.

    uvicorn app.main:app --reload
"""

from __future__ import annotations

import hashlib
import json
import random
from collections import defaultdict
from functools import lru_cache
from pathlib import Path

from fastapi import FastAPI, Header, HTTPException, Response
from pydantic import BaseModel, Field

DATOS = Path(__file__).resolve().parents[2] / "assets" / "balotarios"

app = FastAPI(
    title="Balotarios MTC",
    version="1.0.0",
    description="Datos publicos del examen de conocimientos del MTC (Peru).",
)


# ----------------------------------------------------------------- esquemas

class Topico(BaseModel):
    codigo: str
    nombre: str


class Categoria(BaseModel):
    codigo: str
    nombre: str
    clase: str
    vehiculos: str
    tipo: str
    preguntas_examen: int
    minimo_aprobatorio: int
    duracion_minutos: int
    topicos: list[str]
    pdf: str


class Pregunta(BaseModel):
    id: str
    numero: int
    categoria: str
    topico: str
    enunciado: str
    opciones: list[str]
    respuesta_correcta: int
    explicacion: str | None = None
    imagen: str | None = None


class Simulacro(BaseModel):
    categoria: str
    version: str
    duracion_minutos: int
    minimo_aprobatorio: int
    preguntas: list[Pregunta]


class SolicitudSimulacro(BaseModel):
    """Pesos por topico para sesgar la muestra hacia los puntos debiles.

    El cliente envia su dominio actual (0.0 a 1.0 por topico) y el servidor
    sobrerrepresenta lo flojo. Sin pesos, la muestra es proporcional.
    """

    dominio_por_topico: dict[str, float] = Field(default_factory=dict)
    excluir_ids: list[str] = Field(default_factory=list)
    solo_falladas: bool = False


# -------------------------------------------------------------------- carga

@lru_cache(maxsize=1)
def _catalogo() -> dict:
    return json.loads((DATOS / "catalogo_categorias.json").read_text(encoding="utf-8"))


@lru_cache(maxsize=16)
def _balotario(codigo: str) -> dict:
    ruta = DATOS / f"balotario_{codigo}.json"
    if not ruta.exists():
        raise HTTPException(404, f"No hay balotario cargado para {codigo}")
    return json.loads(ruta.read_text(encoding="utf-8"))


def _categoria(codigo: str) -> dict:
    for c in _catalogo()["categorias"]:
        if c["codigo"] == codigo:
            return c
    raise HTTPException(404, f"Categoria {codigo} no existe")


def _etag(payload: dict) -> str:
    crudo = json.dumps(payload, sort_keys=True, ensure_ascii=False).encode()
    return hashlib.sha256(crudo).hexdigest()[:16]


# ------------------------------------------------------------------ rutas

@app.get("/v1/version")
def version() -> dict:
    """Manifiesto de versiones. El cliente lo consulta al abrir la app y solo
    descarga los balotarios cuyo hash cambio."""
    manifiesto = {}
    for cat in _catalogo()["categorias"]:
        ruta = DATOS / f"balotario_{cat['codigo']}.json"
        if ruta.exists():
            manifiesto[cat["codigo"]] = {
                "hash": hashlib.sha256(ruta.read_bytes()).hexdigest()[:16],
                "preguntas": _balotario(cat["codigo"])["total_preguntas"],
            }
    return {"actualizado": _catalogo()["actualizado"], "balotarios": manifiesto}


@app.get("/v1/topicos", response_model=list[Topico])
def topicos() -> list[dict]:
    return _catalogo()["topicos"]


@app.get("/v1/categorias", response_model=list[Categoria])
def categorias() -> list[dict]:
    return _catalogo()["categorias"]


@app.get("/v1/categorias/{codigo}", response_model=Categoria)
def categoria(codigo: str) -> dict:
    return _categoria(codigo)


@app.get("/v1/categorias/{codigo}/balotario")
def balotario(codigo: str, response: Response, if_none_match: str | None = Header(None)) -> dict:
    datos = _balotario(codigo)
    etag = _etag(datos)
    if if_none_match == etag:
        raise HTTPException(304, "Sin cambios")
    response.headers["ETag"] = etag
    response.headers["Cache-Control"] = "public, max-age=86400"
    return datos


@app.post("/v1/categorias/{codigo}/simulacros", response_model=Simulacro)
def generar_simulacro(codigo: str, solicitud: SolicitudSimulacro) -> dict:
    cat = _categoria(codigo)
    datos = _balotario(codigo)
    banco = [p for p in datos["preguntas"] if p["id"] not in solicitud.excluir_ids]
    cantidad = cat["preguntas_examen"]

    if len(banco) < cantidad:
        raise HTTPException(
            409,
            f"El balotario {codigo} tiene {len(banco)} preguntas y el examen requiere {cantidad}",
        )

    por_topico: dict[str, list[dict]] = defaultdict(list)
    for p in banco:
        por_topico[p["topico"]].append(p)

    # Peso base = proporcion real del topico en el banco.
    # Peso ajustado = base * (1 + (1 - dominio)), es decir hasta el doble de
    # presencia para un topico donde el usuario acierta 0%.
    pesos = {}
    for topico, preguntas in por_topico.items():
        base = len(preguntas) / len(banco)
        dominio = solicitud.dominio_por_topico.get(topico, 1.0)
        pesos[topico] = base * (1 + (1 - min(max(dominio, 0.0), 1.0)))

    total_peso = sum(pesos.values())
    seleccion: list[dict] = []
    for topico, peso in pesos.items():
        cupo = round(peso / total_peso * cantidad)
        seleccion.extend(random.sample(por_topico[topico], min(cupo, len(por_topico[topico]))))

    elegidos = {p["id"] for p in seleccion}
    resto = [p for p in banco if p["id"] not in elegidos]
    random.shuffle(resto)
    while len(seleccion) < cantidad and resto:
        seleccion.append(resto.pop())

    seleccion = seleccion[:cantidad]
    random.shuffle(seleccion)

    return {
        "categoria": codigo,
        "version": _etag(datos),
        "duracion_minutos": cat["duracion_minutos"],
        "minimo_aprobatorio": cat["minimo_aprobatorio"],
        "preguntas": seleccion,
    }


@app.get("/health")
def health() -> dict:
    return {"ok": True}
