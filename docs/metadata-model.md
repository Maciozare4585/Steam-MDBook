# Modelo de metadata V6.6.0

La V6.6.0 agrega una capa de metadata extendida encima del registry de Steam.

## Archivos principales

| Archivo | Función |
|---|---|
| `data/steam-games-registry.json` | Fuente base de identidad Steam: título, App ID, tipo, assets. |
| `data/games-metadata.json` | Fuente extendida: estado personal, DLC, perfiles, recomendación, modos de juego. |
| `data/collection-rules.json` | Reglas futuras para generar colecciones automáticas o sugeridas. |
| `src/assets/data/games-index.json` | Índice consumido por la ficha dinámica del mdBook. |
| `data/generated/collection-suggestions.json` | Vista previa de reglas de colección. |

## Bloques de una ficha

- `steamMetadata`: géneros, tags, descripción, devs, publishers y fecha.
- `playModes`: single-player, multiplayer, co-op, PvP, PvE, MMO.
- `steamFeatures`: logros, Steam Cloud, mando, Workshop, VR, trading cards.
- `dlcInfo`: DLC propios, faltantes, tipo e importancia.
- `playerState`: estado principal y checkboxes personales.
- `recommendationMetadata`: datos para decidir qué jugar según energía, sesión y mood.
- `profileMetadata`: qué significa el juego para Daniel, Jesse o Jovan.
- `libraryPlacement`: colecciones, estados y perfiles donde aparece.
- `dataQuality`: auditoría de metadata, match e IDs dudosos.

## Regla de arquitectura

La ficha del juego se vuelve la fuente de verdad. Las colecciones futuras podrán generarse desde metadata + reglas + overrides manuales.

Las colecciones personales sensibles, como juegos core, favoritos o ZZZ/cuarentena, no deben moverse automáticamente sin confirmación.
