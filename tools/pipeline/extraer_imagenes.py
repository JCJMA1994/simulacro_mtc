"""Extrae las imagenes de senales embebidas en los PDF del balotario.

Usa la posicion vertical de cada fila en las tablas del PDF para asociar
con precision milimetrica la imagen de la senal con el numero de pregunta.

Uso:
    python tools/pipeline/extraer_imagenes.py "sources/pdf/CLASE_A_CATEGORÍA_I - NUEVO.pdf" --out assets/senales/A-I
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def extraer(pdf_path: Path, salida: Path, resolucion: int = 200) -> dict[int, list[str]]:
    import pdfplumber

    salida.mkdir(parents=True, exist_ok=True)
    mapa: dict[int, list[str]] = {}

    with pdfplumber.open(pdf_path) as doc:
        for page_idx, page in enumerate(doc.pages):
            tables = page.find_tables()
            for table in tables:
                grid = table.extract()
                for r_idx, row_cells in enumerate(table.rows):
                    row_text = grid[r_idx]
                    if row_text and row_text[0] and row_text[0].strip().isdigit():
                        q_num = int(row_text[0].strip())
                        valid_cells = [c for c in row_cells.cells if c is not None]
                        if not valid_cells:
                            continue
                        r_top = min(c[1] for c in valid_cells)
                        r_bottom = max(c[3] for c in valid_cells)

                        for img_idx, img in enumerate(page.images):
                            if img["width"] > 20 and img["height"] > 20:
                                if r_top - 5 <= img["top"] <= r_bottom + 5:
                                    bbox = (
                                        max(img["x0"] - 2, 0),
                                        max(img["top"] - 2, 0),
                                        min(img["x1"] + 2, page.width),
                                        min(img["bottom"] + 2, page.height),
                                    )
                                    destino = salida / f"{q_num:04d}_{img_idx}.png"
                                    try:
                                        page.crop(bbox).to_image(resolution=resolucion).save(str(destino))
                                        mapa.setdefault(q_num, []).append(destino.name)
                                    except Exception:
                                        pass

    return mapa


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--resolucion", type=int, default=200)
    args = ap.parse_args()

    mapa = extraer(args.pdf, args.out, args.resolucion)
    print(f"{len(mapa)} preguntas con imagen extraidas en {args.out}")
    for numero, nombres in sorted(mapa.items())[:10]:
        print(f"  Pregunta #{numero:>3} -> {', '.join(nombres)}")

    # Guardar indice json
    indice = args.out / "indice_imagenes.json"
    indice.write_text(json.dumps(mapa, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
