#!/usr/bin/env bash
#
# Compila la app y ensambla "Campanas Yanbal.app" (bundle de barra de menu).
# Requiere macOS 13+ y las Command Line Tools de Xcode (o Xcode).
#
#   ./build.sh          Compila en release y arma el .app en ./build/
#   ./build.sh --open   Ademas abre la app al terminar
#
# Nota: mensajes en ASCII puro a proposito; el bash 3.2 de macOS se atraganta
# con caracteres multibyte (flechas, elipsis) pegados a una variable.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="YanbalCampanas"
APP_DISPLAY="Campanas Yanbal"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_DISPLAY}.app"

echo "==> Compilando en release..."
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="${BIN_DIR}/${APP_NAME}"

echo "==> Ensamblando ${APP_BUNDLE}"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Copiar los bundles de recursos que genera SPM (el isotipo de la barra, etc.)
# junto al binario; asi Bundle.module los encuentra dentro del .app empaquetado.
for b in "${BIN_DIR}"/*.bundle; do
  [ -e "$b" ] && cp -R "$b" "${APP_BUNDLE}/Contents/MacOS/"
done

echo "OK - Listo: ${APP_BUNDLE}"
echo "     Instalalo arrastrandolo a /Applications."

if [[ "${1:-}" == "--open" ]]; then
  open "${APP_BUNDLE}"
fi
