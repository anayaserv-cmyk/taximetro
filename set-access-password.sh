#!/usr/bin/env bash
# Uso: ./set-access-password.sh <nueva-contraseña-de-acceso> [--pruebas <clave-de-pruebas>] [--push]
#      ./set-access-password.sh --pruebas <clave-de-pruebas> [--push]
# Actualiza ACCESS-PASSWORD.txt (chmod 600, ignorado por git), re-cifra index.html y, con --push, hace commit y push.
set -euo pipefail
cd "$(dirname "$0")"
OWNER=""; TESTER=""; PUSH=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pruebas) TESTER="${2:-}"; [ -n "$TESTER" ] || { echo "Falta la clave de pruebas"; exit 1; }; shift 2;;
    --push) PUSH=1; shift;;
    -h|--help) sed -n '2,5p' "$0"; exit 0;;
    -*) echo "Opción desconocida: $1"; exit 1;;
    *) [ -z "$OWNER" ] || { echo "Solo una contraseña de acceso"; exit 1; }; OWNER="$1"; shift;;
  esac
done
[ -n "$OWNER$TESTER" ] || { echo "Uso: $0 <nueva> [--pruebas <clave>] [--push]"; exit 1; }
for v in "$OWNER" "$TESTER"; do case "$v" in *$'\n'*) echo "La contraseña no puede contener saltos de línea"; exit 1;; esac; done
[ -f ACCESS-PASSWORD.txt ] || { echo "Falta ACCESS-PASSWORD.txt"; exit 1; }
CUR_O=$(grep '^ACCESO=' ACCESS-PASSWORD.txt | head -1 | cut -d= -f2-)
CUR_T=$(grep '^PRUEBAS=' ACCESS-PASSWORD.txt | head -1 | cut -d= -f2-)
[ -n "$OWNER" ] && CUR_O="$OWNER"; [ -n "$TESTER" ] && CUR_T="$TESTER"
umask 077
printf 'CONTRASEÑAS DE ACCESO - TAXÍMETRO (no subir a git)\nACCESO=%s\nPRUEBAS=%s\n' "$CUR_O" "$CUR_T" > ACCESS-PASSWORD.txt
chmod 600 ACCESS-PASSWORD.txt
node build.js
if [ "$PUSH" = 1 ]; then
  git add index.html build.js gate.template.html set-access-password.sh .gitignore
  git -c user.name=anayaserv-cmyk -c user.email=anayaserv-cmyk@users.noreply.github.com commit -m "Actualizar contraseña de acceso" || true
  git push origin main
  echo "Publicado. GitHub Pages tarda ~1 minuto."
else
  echo "Listo. Para publicar: git add index.html && git commit && git push (o usa --push)."
fi
echo "Los dispositivos que recordaban la contraseña anterior volverán a pedirla."
