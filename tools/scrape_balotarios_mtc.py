"""
Scraper y extractor de balotarios oficiales del MTC (Peru).

Parsea los PDF de cada categoria publicados por el MTC y los convierte al
esquema JSON que consume la app (assets/balotarios/balotario_<CODIGO>.json).

Requisitos:
    pip install requests pdfplumber

Uso:
    python tools/scrape_balotarios_mtc.py --local sources/pdf --out assets/balotarios --debug
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path

CATALOGO = Path(__file__).resolve().parents[1] / "assets" / "balotarios" / "catalogo_categorias.json"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/126.0 Safari/537.36"
    ),
    "Accept": "application/pdf,*/*",
}

# ---------------------------------------------------------------- modelo

@dataclass
class Pregunta:
    id: str
    numero: int
    categoria: str
    topico: str
    enunciado: str
    opciones: list[str]
    respuesta_correcta: int  # indice 0-based
    explicacion: str = ""
    imagen: str | None = None
    tags: list[str] = field(default_factory=list)


# ------------------------------------------------- clasificacion por topico

REGLAS_TOPICO: list[tuple[str, str]] = [
    (r"\bsenal|señal|semaforo|semáforo|marca en el pavimento|dispositivo de control|reguladora|preventiva|informativa", "SENIALES"),
    (r"\bvelocidad|km/h|kilometros por hora", "VELOCIDAD"),
    (r"\binfraccion|infracción|sancion|sanción|multa|puntos|papeleta|retencion|retención|suspension|suspensión|cancelacion|cancelación", "INFRACCIONES"),
    (r"\blicencia|revalidacion|revalidación|recategorizacion|recategorización|tarjeta de identificacion|tarjeta de propiedad|soat|citv|documento|placa", "DOCUMENTOS"),
    (r"\bprimeros auxilios|herido|hemorragia|reanimacion|reanimación|botiquin|botiquín|torniquete|fractura", "AUXILIOS"),
    (r"\bmotocicleta|mototaxi|trimoto|casco|vehiculo menor|vehículo menor|sidecar|bici|cilindrada", "MOTOS"),
    (r"\bmercancia|mercancía|material peligroso|residuo peligroso|carga|estiba|sobrepeso|bonificacion", "MERCANCIAS"),
    (r"\bpasajero|transporte de personas|servicio de taxi|bus|omnibus|ómnibus|escolar|terminal|asiento|renat", "TRANSPORTE_PERSONAS"),
    (r"\bmotor|neumatico|neumático|freno|aceite|bateria|batería|embrague|mantenimiento|luces|amortiguador|tablero", "MECANICA"),
    (r"\bcontamina|ambiente|emision|emisión|ruido|combustible|humo|catalizador|inspeccion tecnica", "AMBIENTE"),
    (r"\balcohol|alcoholemia|ebriedad|fatiga|cinturon|cinturón|distracci|somnolencia|riesgo|seguridad vial|estupefaciente", "SEGURIDAD"),
]


def clasificar_topico(texto: str, permitidos: list[str]) -> str:
    bajo = texto.lower()
    for patron, topico in REGLAS_TOPICO:
        if topico in permitidos and re.search(patron, bajo):
            return topico
    return "CIRCULACION" if "CIRCULACION" in permitidos else permitidos[0]


# ---------------------------------------------------------------- descarga

def descargar_pdf(url: str, destino: Path, delay: float = 2.0) -> Path:
    import requests

    if destino.exists():
        return destino
    resp = requests.get(url, headers=HEADERS, timeout=60)
    resp.raise_for_status()
    if not resp.content.startswith(b"%PDF"):
        raise RuntimeError(f"La respuesta de {url} no es un PDF (posible bloqueo)")
    destino.write_bytes(resp.content)
    time.sleep(delay)
    return destino


# ----------------------------------------------------------------- parseo

def limpiar_texto(s: str | None) -> str:
    if not s:
        return ""
    texto = " ".join(s.split())
    return texto.strip()


def limpiar_opcion(s: str | None) -> str:
    texto = limpiar_texto(s)
    texto = re.sub(r"^[a-dA-D][\.\)\s]+", "", texto).strip()
    return texto


def extraer_letra_y_explicacion(s: str) -> tuple[int, str]:
    if not s:
        return -1, ""
    m1 = re.match(r"^\s*([a-dA-D])[\.\)\s\:]*$", s)
    if m1:
        return "abcd".index(m1.group(1).lower()), ""
    m2 = re.match(r"^\s*([a-dA-D])[\.\)\s\:]+(.*)$", s)
    if m2:
        return "abcd".index(m2.group(1).lower()), m2.group(2).strip()
    return -1, s


def parsear_fila_tabla(row: list[str | None], categoria: str, topicos_cat: list[str]) -> Pregunta | None:
    if not row or not row[0]:
        return None
    num_str = str(row[0]).strip()
    if not num_str.isdigit():
        return None
    numero = int(num_str)

    celdas = [limpiar_texto(c) for c in row if c is not None and limpiar_texto(c)]
    if len(celdas) < 6:
        return None

    # Determinar si la última celda o penúltima contiene la respuesta
    resp_idx, expl = extraer_letra_y_explicacion(celdas[-1])
    opts_cells = []
    enunciado = ""
    tema = ""

    if resp_idx >= 0:
        # Última celda tiene respuesta
        opts_cells = celdas[-5:-1]
        enunciado = celdas[-6]
        if len(celdas) >= 7:
            tema = celdas[-7]
    elif len(celdas) >= 7:
        # Penúltima celda tiene respuesta y última tiene explicación
        resp_idx_pen, expl_pen = extraer_letra_y_explicacion(celdas[-2])
        if resp_idx_pen >= 0:
            resp_idx = resp_idx_pen
            expl = celdas[-1]
            opts_cells = celdas[-6:-2]
            enunciado = celdas[-7]
            if len(celdas) >= 8:
                tema = celdas[-8]

    # Caso especial para preguntas sobre hoja de ruta electrónica (RENAT 30.3 -> alternativa c)
    if resp_idx == -1 and "hoja de ruta electrónica" in enunciado.lower():
        resp_idx = 2  # c

    letras = ["A", "B", "C", "D"]
    opciones = []
    for idx, o in enumerate(opts_cells):
        limpia = limpiar_opcion(o)
        if not limpia:
            limpia = f"Señal {letras[idx] if idx < 4 else str(idx+1)}"
        opciones.append(limpia)

    if not enunciado or len(opciones) < 3:
        return None

    while len(opciones) < 4:
        idx_falta = len(opciones)
        opciones.append(f"Señal {letras[idx_falta] if idx_falta < 4 else str(idx_falta+1)}")

    texto_clasificacion = f"{tema} {enunciado} {' '.join(opciones)}"
    topico = clasificar_topico(texto_clasificacion, topicos_cat)

    return Pregunta(
        id=f"{categoria}-{numero:04d}",
        numero=numero,
        categoria=categoria,
        topico=topico,
        enunciado=enunciado,
        opciones=opciones,
        respuesta_correcta=resp_idx,
        explicacion=expl,
    )


def extraer_preguntas_pdf(pdf_path: Path, categoria: str, topicos: list[str]) -> list[Pregunta]:
    import pdfplumber

    preguntas: list[Pregunta] = []
    vistos: set[int] = set()

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            tables = page.extract_tables()
            for table in tables:
                for row in table:
                    pregunta = parsear_fila_tabla(row, categoria, topicos)
                    if pregunta and pregunta.numero not in vistos:
                        vistos.add(pregunta.numero)
                        preguntas.append(pregunta)

    preguntas.sort(key=lambda p: p.numero)
    return preguntas


# ------------------------------------------------------------------- main

def resolver_pdf_local(cache_dir: Path, codigo: str, url_pdf: str) -> Path | None:
    from urllib.parse import unquote

    candidatos = [
        cache_dir / f"{codigo}.pdf",
        cache_dir / f"{codigo.lower()}.pdf",
    ]
    nombre_url = unquote(url_pdf.split("/")[-1])
    if nombre_url and nombre_url.endswith(".pdf"):
        candidatos.append(cache_dir / nombre_url)

    for c in candidatos:
        if c.exists():
            return c

    partes = codigo.split("-")
    if len(partes) == 2:
        clase, cat = partes[0].upper(), partes[1].upper()
        for p in cache_dir.glob("*.pdf"):
            nombre_norm = (
                p.stem.upper()
                .replace("Í", "I")
                .replace(" ", "_")
                .replace("-", "_")
            )
            patron = rf"CLASE_{clase}_CATEGORIA_{cat}(?:_|\b|$)"
            if re.search(patron, nombre_norm):
                return p

    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/balotarios")
    ap.add_argument("--cache", default=".cache_pdf")
    ap.add_argument("--local", help="carpeta con PDFs ya descargados a mano")
    ap.add_argument("--solo", help="procesar solo una categoria, ej. A-I")
    ap.add_argument("--debug", action="store_true")
    args = ap.parse_args()

    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    salida = Path(args.out)
    salida.mkdir(parents=True, exist_ok=True)
    cache = Path(args.local) if args.local else Path(args.cache)
    cache.mkdir(parents=True, exist_ok=True)

    resumen = []
    for cat in catalogo["categorias"]:
        codigo = cat["codigo"]
        if args.solo and args.solo != codigo:
            continue
        pdf_local = resolver_pdf_local(cache, codigo, cat["pdf"])
        try:
            if pdf_local is None or not pdf_local.exists():
                if args.local:
                    print(f"[!] falta PDF para {codigo} en {cache}")
                    continue
                pdf_local = cache / f"{codigo}.pdf"
                descargar_pdf(cat["pdf"], pdf_local)
            preguntas = extraer_preguntas_pdf(pdf_local, codigo, cat["topicos"])
            con_clave = sum(1 for p in preguntas if p.respuesta_correcta >= 0)
        except Exception as exc:  # noqa: BLE001
            print(f"[x] {codigo}: {exc}", file=sys.stderr)
            continue

        destino = salida / f"balotario_{codigo}.json"
        destino.write_text(
            json.dumps(
                {
                    "categoria": codigo,
                    "fuente": cat["pdf"],
                    "total_preguntas": len(preguntas),
                    "preguntas": [asdict(p) for p in preguntas],
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        resumen.append((codigo, len(preguntas), con_clave))
        if args.debug and preguntas:
            print(f"\n--- Muestra de {codigo} (Pregunta 1) ---")
            print(json.dumps(asdict(preguntas[0]), ensure_ascii=False, indent=2))

    print("\n" + "=" * 40)
    print(f"{'CATEGORIA':<12} {'PREGUNTAS':<12} {'CON CLAVE':<12}")
    print("-" * 40)
    for codigo, total, con_clave in resumen:
        print(f"{codigo:<12} {total:<12} {con_clave:<12}")
    print("=" * 40)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
