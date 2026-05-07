# V6.5.14 — Hotfix de registry, parser y ficha dinámica

## Objetivo

Corregir la sincronización de juegos detectados desde Markdown, especialmente en tablas donde `Juego` no está en la primera columna, como `ZZZ) El Pozo` y `ZZZ) MRD`.

## Cambios aplicados

- Parser de tablas endurecido para detectar la columna `Juego` en cualquier posición.
- Limpieza de títulos contaminados por tooltips ya renderizados, evitando casos `JuegoJuego`.
- Eliminación de entradas corruptas del registry generadas por fuzzy matching peligroso.
- Regeneración de `steam-image-targets.json` desde el registry limpio.
- Regeneración de `steam-games-review-needed.json` con pendientes reales descubiertos desde Markdown.
- Tooltips extendidos a colecciones, estados, decisión y perfiles personales.
- `Dead as Disco` queda integrado como tooltip y la colección `Música / Ritmo` pasa a 7 juegos.
- Se agrega una ficha dinámica única: `07-juegos/detalle.html?id=STEAM_APP_ID`.
- Se agrega `src/assets/data/games-index.json` como índice consumible por JavaScript.
- Se eliminan archivos accidentales de raíz: `-UpdateMarkdownPages` y `-UpdateTargets`.
- Se recuperan entradas válidas que ya tenían tooltip/AppID previo: `DOOM + DOOM II` y `Half-Life 2: Deathmatch`.
- Se agrega alias de `DOOM 3: BFG Edition` sobre AppID `208200` para respetar el nombre visible de la colección.

## Resultado técnico

| Métrica | Resultado |
|---|---:|
| Entradas corruptas removidas del registry | 21 |
| Registry limpio | 782 entradas |
| Pendientes reales en review-needed | 240 |
| Archivos con tooltips actualizados | 97 |

## Nota

Esta versión no consulta APIs externas. Deja el proyecto limpio para que en la PC local puedas ejecutar el sync con menos falsos positivos y sin reescrituras innecesarias.
