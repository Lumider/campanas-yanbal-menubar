#!/usr/bin/env bash
#
# Crea un instalador .dmg de "Campanas Yanbal.app" (el clásico "arrastra a
# Aplicaciones"). Usa solo hdiutil, así que NO requiere instalar nada extra.
#
#   ./make-dmg.sh
#
# Genera build/Campanas Yanbal.dmg. Ábrelo, arrastra la app a la carpeta
# Aplicaciones que aparece, y listo.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="YanbalCampanas"
APP_DISPLAY="Campanas Yanbal"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_DISPLAY}.app"
STAGE="${BUILD_DIR}/dmg-stage"
DMG="${BUILD_DIR}/${APP_DISPLAY}.dmg"

# 1) Compila la app (reutiliza build.sh).
echo "==> Compilando la app..."
./build.sh

# 2) Prepara el contenido del .dmg: la app + un acceso a /Applications.
echo "==> Preparando el instalador..."
rm -rf "${STAGE}" "${DMG}"
mkdir -p "${STAGE}"
cp -R "${APP_BUNDLE}" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

# 3) Empaqueta el .dmg comprimido.
echo "==> Creando ${DMG}..."
hdiutil create \
  -volname "${APP_DISPLAY}" \
  -srcfolder "${STAGE}" \
  -ov -format UDZO \
  "${DMG}" >/dev/null

rm -rf "${STAGE}"

echo "OK - Listo: ${DMG}"
echo "     Abrelo (doble clic) y arrastra la app sobre Aplicaciones."
