"""Controlla che ogni carattere scritto negli script e nei dati esista nei font del gioco.

Uso: python3 tools/controlla_glifi.py   (esce con errore se trova caratteri che apparirebbero come quadratini)
Controlla le stringhe degli script .gd e tutti i testi dei file data/*.json contro Exo 2 (testo) e Oxanium (titoli).
"""
import glob, json, re, sys
from fontTools.ttLib import TTFont

FONTS = {"Exo2": "assets/fonts/Exo2.ttf", "Oxanium": "assets/fonts/Oxanium.ttf"}
cmaps = {k: set(TTFont(f).getBestCmap().keys()) for k, f in FONTS.items()}
comuni = set.intersection(*cmaps.values())
bad = {}

def controlla(testo, dove):
    for ch in testo:
        if ord(ch) > 126 and ord(ch) not in comuni and ch not in "\n\t":
            bad.setdefault(ch, []).append(dove)

for f in glob.glob("scripts/**/*.gd", recursive=True):
    for n, line in enumerate(open(f, encoding="utf-8"), 1):
        code = line.split("#", 1)[0] if not line.lstrip().startswith("##") else ""
        for s in re.findall(r'"((?:[^"\\]|\\.)*)"', code):
            controlla(s, "%s:%d" % (f, n))

def walk(x, dove):
    if isinstance(x, dict):
        for k, v in x.items():
            walk(v, dove + "." + str(k))
    elif isinstance(x, list):
        for i, v in enumerate(x):
            walk(v, dove)
    elif isinstance(x, str):
        controlla(x, dove)

for f in glob.glob("data/*.json"):
    walk(json.load(open(f, encoding="utf-8")), f)

for ch, where in bad.items():
    print("MANCA %r U+%04X: %s" % (ch, ord(ch), ", ".join(sorted(set(where))[:5])))
print("glifi ok" if not bad else "%d caratteri non disponibili" % len(bad))
sys.exit(1 if bad else 0)
