"""Puerta de calidad. Si esto falla, el JSON no se publica.

    python tools/pipeline/validar.py assets/balotarios --strict
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

CATALOGO = "catalogo_categorias.json"


def validar(carpeta: Path, estricto: bool) -> int:
    catalogo = json.loads((carpeta / CATALOGO).read_text(encoding="utf-8"))
    topicos_validos = {t["codigo"] for t in catalogo["topicos"]}
    problemas: list[str] = []
    advertencias: list[str] = []

    for cat in catalogo["categorias"]:
        codigo = cat["codigo"]
        archivo = carpeta / f"balotario_{codigo}.json"
        if not archivo.exists():
            (problemas if estricto else advertencias).append(f"{codigo}: falta {archivo.name}")
            continue

        datos = json.loads(archivo.read_text(encoding="utf-8"))
        preguntas = datos["preguntas"]
        vistos: Counter[tuple[str, tuple[str, ...]]] = Counter()

        if len(preguntas) < cat["preguntas_examen"]:
            problemas.append(
                f"{codigo}: {len(preguntas)} preguntas, el examen necesita {cat['preguntas_examen']}"
            )

        for p in preguntas:
            ref = f"{codigo}#{p.get('numero')}"
            if not p.get("enunciado", "").strip():
                problemas.append(f"{ref}: enunciado vacio")
            if len(p.get("opciones", [])) != 4:
                problemas.append(f"{ref}: {len(p.get('opciones', []))} opciones, se esperan 4")
            if any(not o.strip() for o in p.get("opciones", [])):
                problemas.append(f"{ref}: opcion vacia")
            idx = p.get("respuesta_correcta", -1)
            if not 0 <= idx < len(p.get("opciones", [])):
                problemas.append(f"{ref}: sin clave de respuesta valida")
            if p.get("topico") not in topicos_validos:
                problemas.append(f"{ref}: topico desconocido '{p.get('topico')}'")

            clave_duplicado = (p.get("enunciado", "").strip(), tuple(p.get("opciones", [])))
            vistos[clave_duplicado] += 1

        for (enunciado, _), veces in vistos.items():
            if veces > 1:
                advertencias.append(f"{codigo}: pregunta duplicada x{veces}: {enunciado[:60]}...")

        # Verificar tópicos presentes
        por_topico = Counter(p["topico"] for p in preguntas)
        for topico in cat["topicos"]:
            if por_topico[topico] == 0:
                advertencias.append(f"{codigo}: no tiene preguntas para el topico {topico}")
            elif por_topico[topico] < 3:
                advertencias.append(
                    f"{codigo}: topico {topico} tiene pocas preguntas ({por_topico[topico]})"
                )

    for adv in advertencias:
        print(f"[!] {adv}")

    for p in problemas:
        print(f"[x] {p}", file=sys.stderr)

    if problemas:
        print(f"\n{len(problemas)} problemas criticos encontrados", file=sys.stderr)
        return 1
    print("validacion ok")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("carpeta", type=Path)
    ap.add_argument("--strict", action="store_true")
    args = ap.parse_args()
    return validar(args.carpeta, args.strict)


if __name__ == "__main__":
    raise SystemExit(main())
