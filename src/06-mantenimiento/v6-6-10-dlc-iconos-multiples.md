# V6.6.10 — DLC con iconos múltiples

## Objetivo

Corregir el template y la ficha dinámica de DLC para que el estado se indique **solo con iconos**, permitiendo **más de un icono por DLC**.

## Cambios

- Se agrega `dlcInfo.dlcs[].markers` como arreglo preferente.
- Se conserva `dlcInfo.dlcs[].marker` solo como campo legado de compatibilidad.
- La tabla de DLC cambia de `Marca / DLC / Tipo / Estado` a `Iconos / DLC / Tipo`.
- Cada fila muestra únicamente iconos; el texto descriptivo queda como tooltip y accesibilidad.
- El render puede mostrar combinaciones como:
  - `✅ 🧩` para DLC propio + expansión/pack.
  - `⬜ 🎵` para soundtrack faltante.
  - `🚫 💰` para moneda/consumible descartado.
  - `🆓 🎨` para contenido gratuito cosmético.
- `scripts/18-sync-steam-dlc.ps1` ahora conserva `markers` manuales, migra `marker` legado y puede inicializar iconos múltiples.
- `data/games-metadata.json` y `src/assets/data/games-index.json` fueron migrados para que todos los DLC tengan `markers`.
- Se agrega el template copiable `16-template-de-metadata-dlc-iconos.md`.

## Modelo recomendado

```json
{
  "appId": 2778580,
  "title": "ELDEN RING Shadow of the Erdtree",
  "type": "dlc",
  "markers": ["owned", "pass"],
  "important": true,
  "isFree": false
}
```

## Validación

- `theme/game-detail.js`: validado con `node --check`.
- `data/games-metadata.json`: JSON válido.
- `src/assets/data/games-index.json`: JSON válido.
- `SUMMARY.md`: sin enlaces rotos.
- Todos los DLC en metadata e índice tienen `markers`.
