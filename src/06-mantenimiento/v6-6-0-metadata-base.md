# V6.6.0 — Metadata base y ficha extendida

## Objetivo

Convertir la ficha dinámica de juego en una vista general real: no solo Steam App ID e imagen, sino estado personal, DLC, modos de juego, features, recomendaciones y significado por perfil.

## Cambios principales

- Se agrega `data/games-metadata.json` como capa de metadata extendida.
- Se agrega `data/collection-rules.json` como base para colecciones automáticas/sugeridas.
- Se agrega `data/schemas/game-metadata.schema.json`.
- Se agrega `data/generated/collection-suggestions.json` como preview de reglas.
- Se expande `src/assets/data/games-index.json` con metadata extendida.
- Se rediseña `theme/game-detail.js` para mostrar:
  - resumen Steam;
  - estado personal;
  - modos de juego;
  - features Steam;
  - DLC / contenido adicional;
  - recomendación;
  - ubicación;
  - significado por perfil.
- Se agregan scripts:
  - `14-generate-games-metadata-base.ps1`;
  - `15-build-games-index-with-metadata.ps1`;
  - `16-preview-collection-rules.ps1`.

## Nuevos juegos integrados

- `Exploding Kittens® 2` → `YYY) Party / Versus / Mesa`.
- `FIVE NIGHTS AT FREDDY'S: HELP WANTED` → `VR` solamente.

## Regla de arquitectura

`data/steam-games-registry.json` sigue siendo la fuente de identidad Steam.

`data/games-metadata.json` se vuelve la fuente para estado personal, perfiles, DLC, recomendación y colecciones automáticas futuras.

Las colecciones generadas deben respetar overrides manuales y no deben promover juegos desde `ZZZ` sin confirmación.
