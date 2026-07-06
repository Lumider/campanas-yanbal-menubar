# Calendario de campañas Yanbal

> Referencia de fechas, semanas y cierres que usa el motor de cálculo del plugin.
> Años 2024–2027 (extraído del calendario oficial de Yanbalnet).

## Las reglas del calendario

1. **13 campañas por año**, numeradas C01–C13, **contiguas y sin huecos**: cada
   campaña empieza el día siguiente del cierre de la anterior.
2. **Cada campaña dura exactamente 4 semanas (28 días)** → S1, S2, S3, S4.
   Esa es la notación de Maya (ej. "C7 - S2").
3. **La semana campañal va de sábado a viernes**: toda campaña inicia sábado
   y cierra viernes.
4. 13 × 28 = **364 días**, un día menos que el año calendario. Por eso el
   arranque se corre y, cada ciertos años, una **C13 extendida de 5 semanas
   (35 días)** reajusta el calendario — ocurrió en 2024 (C13: 30 nov 2024 → 3 ene 2025).
5. La C13 siempre cruza el Año Nuevo: el "año campañal" no coincide
   exactamente con el año calendario.

## Cómo lo calcula el plugin

El motor no hardcodea las 13 campañas: parte de una **tabla de anclas** con la
fecha de inicio (sábado) de C01 de cada año y deriva el resto por aritmética:

- C01–C12 del año Y: `inicio = anclaC01(Y) + (n−1)·28 días`, cierre a los 27 días.
- C13 del año Y: desde el día siguiente al cierre de C12 hasta la víspera del
  C01 del año siguiente → los 28 o 35 días de C13 salen solos entre dos anclas.
- Semana dentro de la campaña: `⌈(hoy − inicioCampaña + 1) / 7⌉`.

Las anclas viven en `anclasC01` dentro de `Sources/CampaignKit/CampaignCalendar.swift`.

## Anclas de C01 (inicio, sábado)

| Año | Inicio de C01 |
|---|---|
| 2024 | 30 dic 2023 |
| 2025 | 4 ene 2025 |
| 2026 | 3 ene 2026 |
| 2027 | 2 ene 2027 |

## 2026

| Campaña | Inicio (sáb) | Fin (vie) |
|---|---|---|
| C01 | 3 ene | 30 ene |
| C02 | 31 ene | 27 feb |
| C03 | 28 feb | 27 mar |
| C04 | 28 mar | 24 abr |
| C05 | 25 abr | 22 may |
| C06 | 23 may | 19 jun |
| C07 | 20 jun | 17 jul |
| C08 | 18 jul | 14 ago |
| C09 | 15 ago | 11 set |
| C10 | 12 set | 9 oct |
| C11 | 10 oct | 6 nov |
| C12 | 7 nov | 4 dic |
| C13 | 5 dic | 1 ene 2027 |

## 2025

| Campaña | Inicio | Fin |
|---|---|---|
| C01 | 4 ene | 31 ene |
| C02 | 1 feb | 28 feb |
| C03 | 1 mar | 28 mar |
| C04 | 29 mar | 25 abr |
| C05 | 26 abr | 23 may |
| C06 | 24 may | 20 jun |
| C07 | 21 jun | 18 jul |
| C08 | 19 jul | 15 ago |
| C09 | 16 ago | 12 set |
| C10 | 13 set | 10 oct |
| C11 | 11 oct | 7 nov |
| C12 | 8 nov | 5 dic |
| C13 | 6 dic | 2 ene 2026 |

## 2024 (con C13 extendida)

| Campaña | Inicio | Fin |
|---|---|---|
| C01 | 30 dic 2023 | 26 ene |
| C02 | 27 ene | 23 feb |
| C03 | 24 feb | 22 mar |
| C04 | 23 mar | 19 abr |
| C05 | 20 abr | 17 may |
| C06 | 18 may | 14 jun |
| C07 | 15 jun | 12 jul |
| C08 | 13 jul | 9 ago |
| C09 | 10 ago | 6 set |
| C10 | 7 set | 4 oct |
| C11 | 5 oct | 1 nov |
| C12 | 2 nov | 29 nov |
| **C13** | **30 nov** | **3 ene 2025 (35 días · 5 semanas)** |

## Añadir años futuros

Cuando Yanbal publique el C01 de un año nuevo, añade su ancla en `anclasC01`
(`Sources/CampaignKit/CampaignCalendar.swift`). Con eso, la C13 del año anterior se
recalcula automáticamente. Mientras no exista el ancla del año siguiente, la C13 se
asume de 4 semanas.
