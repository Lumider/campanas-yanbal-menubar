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

# Icono de la app (la Y sobre naranja): compila el iconset a .icns con iconutil
# (incluido en macOS) y lo copia al bundle. Referenciado como CFBundleIconFile.
echo "==> Generando icono (AppIcon.icns)..."
iconutil -c icns "Resources/AppIcon.iconset" -o "${BUILD_DIR}/AppIcon.icns"
cp "${BUILD_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# Firma ad-hoc (identidad local, sin cuenta de developer). Sin firma, macOS
# rechaza el registro en el centro de notificaciones: no aparece ni el prompt
# de permiso. Con la firma ad-hoc las notificaciones locales funcionan.
echo "==> Firmando (ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "OK - Listo: ${APP_BUNDLE}"
echo "     Instalalo arrastrandolo a /Applications."

if [[ "${1:-}" == "--open" ]]; then
  open "${APP_BUNDLE}"
fi
