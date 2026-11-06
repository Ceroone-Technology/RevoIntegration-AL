#!/bin/sh
# Regenera el registro del paso a producción (HTML y Word) en docs/ a partir de registro.md (macOS).
# Uso: sh docs/registro/exportar.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/.."
BASE="Registro del paso a produccion - Integracion Revo BC (GAL)"
python3 -I "$DIR/md_to_html.py" "$DIR/registro.md" "$OUT/$BASE.html" "$(date '+%d/%m/%Y %H:%M') (hora local)" > /dev/null
textutil -convert docx -output "$OUT/$BASE.docx" "$OUT/$BASE.html"
ls -l "$OUT/$BASE.html" "$OUT/$BASE.docx"
