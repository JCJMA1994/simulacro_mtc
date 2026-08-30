"""Diff entre el JSON recien generado y el publicado, por clave estable.

La clave estable es sha1(categoria + enunciado normalizado). Si el MTC
renumera las preguntas, la clave no cambia y el progreso del usuario sigue
apuntando a la misma pregunta. Sin esto, cada re-scrape invalida el historial.

    python tools/pipeline/diff.py assets/balotarios --salida diff.md
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


def normalizar(texto: str) -> str:
    texto = texto.lower().replace("-\n", "").replace("\n", " ")
    return re.sub(r"[^a-z0-9áéíóúñ ]", "", re.sub(r"\s+", " ", texto)).strip()


def clave_estable(categoria: str, enunciado: str) -> str:
    return hashlib.sha1(f"{categoria}|{normalizar(enunciado)}".encode()).hexdigest()[:16]


def indexar(preguntas: list[dict], categoria: str) -> dict[str, dict]:
    return {clave_estable(categoria, p["enunciado"]): p for p in preguntas}


def version_publicada(ruta: Path) -> list[dict] | None:
    try:
        crudo = subprocess.run(
            ["git", "show", f"HEAD:{ruta}"], capture_output=True, text=True, check=True
        ).stdout
        return json.loads(crudo)["preguntas"]
    except Exception:
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("carpeta", type=Path)
    ap.add_argument("--salida", type=Path, default=Path("diff.md"))
    args = ap.parse_args()

    lineas = ["# Cambios en los balotarios", ""]
    hubo_cambios = False

    for archivo in sorted(args.carpeta.glob("balotario_*.json")):
        categoria = archivo.stem.removeprefix("balotario_")
        nuevas = indexar(json.loads(archivo.read_text(encoding="utf-8"))["preguntas"], categoria)
        anteriores_raw = version_publicada(archivo)

        if anteriores_raw is None:
            lineas += [f"## {categoria}", f"- nuevo balotario con {len(nuevas)} preguntas", ""]
            hubo_cambios = True
            continue

        anteriores = indexar(anteriores_raw, categoria)
        agregadas = nuevas.keys() - anteriores.keys()
        eliminadas = anteriores.keys() - nuevas.keys()
        modificadas = {
            k
            for k in nuevas.keys() & anteriores.keys()
            if nuevas[k]["opciones"] != anteriores[k]["opciones"]
            or nuevas[k]["respuesta_correcta"] != anteriores[k]["respuesta_correcta"]
        }

        if not (agregadas or eliminadas or modificadas):
            continue

        hubo_cambios = True
        lineas += [
            f"## {categoria}",
            f"- agregadas: {len(agregadas)}",
            f"- eliminadas: {len(eliminadas)}",
            f"- modificadas (opciones o clave): {len(modificadas)}",
            "",
        ]
        if modificadas:
            lineas.append("Cambio la respuesta o las opciones. Revisar a mano antes de publicar:")
            for k in list(modificadas)[:10]:
                lineas.append(f"- {nuevas[k]['enunciado'][:90]}...")
            lineas.append("")

    if not hubo_cambios:
        lineas.append("Sin cambios respecto de la version publicada.")

    args.salida.write_text("\n".join(lineas), encoding="utf-8")
    print("\n".join(lineas))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
