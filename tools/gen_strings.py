#!/usr/bin/env python3
"""Genera los textos de las apps nativas a partir de i18n/textos.csv.

Uso (desde cualquier carpeta):
    python tools/gen_strings.py            # escribe los dos archivos
    python tools/gen_strings.py --check    # no escribe; falla si están desactualizados

Salidas:
    iOS:     native/ios/RutaKidsSpike/es.lproj/Localizable.strings (spike)
             native/ios/RutaKids/Resources/es.lproj/Localizable.strings (app)
    Android: native/android/app/src/main/res/values/strings.xml

El CSV es la única fuente de textos (hallazgo H8). No edites a mano los archivos generados.
"""
import csv
import sys
from pathlib import Path
from xml.sax.saxutils import escape

RAIZ = Path(__file__).resolve().parent.parent
CSV = RAIZ / "i18n" / "textos.csv"
IOS_SPIKE = RAIZ / "native" / "ios" / "RutaKidsSpike" / "es.lproj" / "Localizable.strings"
IOS_APP = RAIZ / "native" / "ios" / "RutaKids" / "Resources" / "es.lproj" / "Localizable.strings"
ANDROID = RAIZ / "native" / "android" / "app" / "src" / "main" / "res" / "values" / "strings.xml"

AVISO = "Generado por tools/gen_strings.py desde i18n/textos.csv. No editar a mano."


def leer_textos() -> dict[str, str]:
    textos: dict[str, str] = {}
    with CSV.open(encoding="utf-8", newline="") as f:
        for n, fila in enumerate(csv.DictReader(f), start=2):
            clave = (fila.get("keys") or "").strip()
            if not clave:
                continue
            if not clave.replace("_", "").isalnum():
                raise SystemExit(f"{CSV.name}:{n}: clave inválida '{clave}' (solo letras, números y _)")
            if clave in textos:
                raise SystemExit(f"{CSV.name}:{n}: clave repetida '{clave}'")
            textos[clave] = fila.get("es") or ""
    return textos


def texto_android(valor: str) -> str:
    v = escape(valor)
    v = v.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')
    v = v.replace("\n", "\\n").replace("@", "\\@")
    if v.startswith("?"):
        v = "\\" + v
    return v


def generar_android(textos: dict[str, str]) -> str:
    lineas = ['<?xml version="1.0" encoding="utf-8"?>', f"<!-- {AVISO} -->", "<resources>"]
    for clave, valor in textos.items():
        extra = ' formatting="false"' if "%" in valor else ""
        lineas.append(f'    <string name="{clave}"{extra}>{texto_android(valor)}</string>')
    lineas.append("</resources>")
    return "\n".join(lineas) + "\n"


def generar_ios(textos: dict[str, str]) -> str:
    lineas = [f"/* {AVISO} */"]
    for clave, valor in textos.items():
        v = valor.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        lineas.append(f'"{clave}" = "{v}";')
    return "\n".join(lineas) + "\n"


def main() -> int:
    revisar = "--check" in sys.argv[1:]
    textos = leer_textos()
    texto_ios = generar_ios(textos)
    salidas = {ANDROID: generar_android(textos), IOS_SPIKE: texto_ios, IOS_APP: texto_ios}
    desactualizados = []
    for ruta, contenido in salidas.items():
        actual = ruta.read_text(encoding="utf-8") if ruta.exists() else None
        if actual == contenido:
            continue
        desactualizados.append(ruta)
        if not revisar:
            ruta.parent.mkdir(parents=True, exist_ok=True)
            ruta.write_text(contenido, encoding="utf-8", newline="\n")
            print(f"Escrito {ruta.relative_to(RAIZ)} ({len(textos)} textos)")
    if revisar and desactualizados:
        for ruta in desactualizados:
            print(f"Desactualizado: {ruta.relative_to(RAIZ)}")
        return 1
    if not desactualizados:
        print("Todo al día.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
