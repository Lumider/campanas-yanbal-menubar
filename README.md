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

### Modo desarrollo rápido

```bash
swift run       # ejecuta sin empaquetar el .app
swift test      # corre las pruebas del motor de cálculo
```

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
Sources/YanbalCampanas/
  YanbalCampanasApp.swift             @main + escena MenuBarExtra + refresco
  PanelView.swift                     UI del popover
Tests/CampaignKitTests/               Pruebas del motor (bordes de año, C13 extendida)
Resources/Info.plist                  LSUIElement (sin Dock), id y versión
build.sh                              Compila y arma el .app
CALENDARIO.md                         Reglas y fechas del calendario campañal Yanbal
```

## Versión para iPhone (widget)

El widget de iOS vive en un repositorio aparte: **`campanas-yanbal-ios`**.
