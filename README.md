# Campañas Yanbal — app de barra de menú (macOS)

Pequeña app que vive en la **barra de menú** de macOS y muestra en qué **campaña y
semana** del calendario Yanbal estás hoy, cuándo cierra y cuáles son las próximas.

- Barra de menú: `C7 · S3`
- Al hacer clic:
  - `Campaña C7 · Semana 3 de 4` con su rango de fechas
  - `Cierra el viernes 17 jul · faltan 11 días`
  - `Próximas campañas`: C8, C9, C10…

Sin icono en el Dock, sin ventana: solo la barra de menú.

## Requisitos

- macOS 13 (Ventura) o superior.
- **Command Line Tools de Xcode** (o Xcode completo). Instálalas con:
  ```bash
  xcode-select --install
  ```

## Compilar e instalar

Desde la raíz del proyecto:

```bash
./build.sh          # compila y arma "build/Campanas Yanbal.app"
./build.sh --open   # además la abre al terminar
```

Verás `C7 · S3` (o la campaña que corresponda a hoy) en la barra de menú.
En Finder la app se muestra como **Campañas Yanbal** (nombre del `Info.plist`);
el archivo en disco es `Campanas Yanbal.app` (sin ñ, por compatibilidad del script).

Para dejarla instalada: arrastra `build/Campanas Yanbal.app` a `/Applications`.
Para que arranque sola al iniciar sesión: **Ajustes del Sistema → General →
Ítems de inicio → +** y elige la app.

> La primera vez, macOS puede bloquearla por Gatekeeper (app sin firmar). Si pasa:
> **Ajustes del Sistema → Privacidad y seguridad → “Abrir de todos modos”**, o bien
> clic derecho sobre la app → **Abrir**.

### Crear un instalador .dmg

Para tener el clásico instalador de Mac (arrastrar la app a Aplicaciones), sin
instalar nada extra:

```bash
./make-dmg.sh
```

Genera `build/Campanas Yanbal.dmg`. Ábrelo con doble clic y arrastra la app sobre
la carpeta **Aplicaciones** que aparece. (Sigue siendo una app sin firmar, así que
la primera vez aplica la misma nota de Gatekeeper de arriba.)

### Modo desarrollo rápido

```bash
swift run       # ejecuta sin empaquetar el .app
swift test      # corre las pruebas del motor de cálculo
```

## Fechas importantes y notificaciones (avisos remotos)

La app muestra una sección **"Fechas importantes"** en el panel y manda
**notificaciones de macOS**. Los avisos viven en [`fechas.json`](fechas.json)
en la rama `main`: **publicar un aviso = editar ese archivo en GitHub** (desde el
navegador). Todas las apps instaladas lo consultan cada 6 horas — nadie reinstala.

Formato de cada aviso:

```json
{
  "fecha": "2026-07-25",
  "titulo": "Convención de líderes",
  "detalle": "Lima · confirmar asistencia",
  "avisarDiasAntes": 7
}
```

- `avisarDiasAntes` (opcional, 3 por defecto): con cuánta anticipación se notifica
  y se resalta el chip en naranja. Cada aviso notifica al entrar en su ventana y
  el mismo día (9:00). Además la app avisa el **cierre de campaña** (3 días antes
  y el viernes de cierre).
- Sin conexión, la app usa la última copia descargada. Un JSON mal editado se
  ignora (no rompe lo que la gente ve).
- **Requisito:** el repo debe ser **público** para que las apps lean
  `raw.githubusercontent.com/.../main/fechas.json` sin credenciales.
- La primera vez, macOS pedirá permiso para notificar (Permitir).

## Cómo calcula las campañas

El calendario Yanbal divide el año en **13 campañas de 4 semanas (sábado→viernes)**.
Como 13×28 = 364 días (uno menos que el año), el arranque se corre y cada ciertos
años una **C13 de 5 semanas** reajusta el calendario.

El motor (`Sources/CampaignKit/CampaignCalendar.swift`) parte de una **tabla de
anclas**: la fecha de inicio de C01 por año, tomada del calendario oficial
(ver [`CALENDARIO.md`](CALENDARIO.md)). De ahí deriva las 13 campañas por
aritmética de fechas; la duración de C13 (28 o 35 días) sale sola entre dos anclas
consecutivas.

### Añadir un año nuevo

Cuando Yanbal publique el C01 de un año que no esté en la tabla, añade su ancla en
`anclasC01` dentro de `Sources/CampaignKit/CampaignCalendar.swift`:

```swift
2028: DateComponents(year: 2028, month: 1, day: 1),  // ejemplo
```

Con eso, la C13 del año anterior se recalcula automáticamente. Mientras no exista el
ancla del año siguiente, la C13 se asume de 4 semanas.

## Estructura

```
Package.swift                         Paquete Swift (librería + ejecutable, macOS 13+)
Sources/CampaignKit/
  CampaignCalendar.swift              Motor de cálculo (anclas + aritmética, Foundation puro)
  YanbalIso.swift                     Isotipo "Y" de Yanbal como Shape SwiftUI
Sources/YanbalCampanas/
  YanbalCampanasApp.swift             @main + escena MenuBarExtra + refresco
  PanelView.swift                     UI del popover (con el iso de Yanbal)
Tests/CampaignKitTests/               Pruebas del motor (bordes de año, C13 extendida)
Resources/Info.plist                  LSUIElement (sin Dock), id y versión
Resources/AppIcon.iconset/            Ícono de la app (Y sobre naranja); build.sh lo compila a .icns
build.sh                              Compila y arma el .app
make-dmg.sh                           Crea el instalador .dmg
CALENDARIO.md                         Reglas y fechas del calendario campañal Yanbal
```

## Versión para iPhone (widget)

El widget de iOS vive en un repositorio aparte: **`campanas-yanbal-ios`**.
