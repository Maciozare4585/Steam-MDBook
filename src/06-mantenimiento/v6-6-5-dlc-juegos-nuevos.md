# V6.6.5 · DLC y juegos nuevos

## Objetivo

Registrar información manual reciente sobre propiedad de DLC y agregar los cuatro juegos nuevos detectados en Steam sin crear una sección nueva de inbox.

## Juegos nuevos agregados

| Juego | Steam App ID | Colecciones aplicadas |
|---|---:|---|
| Blue Protocol: Star Resonance | `3681810` | Internet Persistente, RPG, YYY) PvE / Acción |
| Desktop Mate | `3301060` | ZZZ) Demos y otros |
| Supermarket Together | `2709570` | Simulator, Chill / Relax, Arcade / Casual, YYY) Party / Versus / Mesa |
| Transformice | `335240` | Internet Persistente, Plataformas, Arcade / Casual, YYY) Party / Versus / Mesa |

## DLC registrado manualmente

| Estado | Juegos / sagas |
|---|---|
| Full DLC | The Witcher 3, Fallout 3, Fallout New Vegas, Fallout 4, DAVE THE DIVER, NieR, Stellar Blade, Civilization V, Civilization VI, Dragon Ball FighterZ, Dying Light 1, Halo MCC, Mortal Kombat 11, Metal: Hellsinger |
| DLC principal propio | Elden Ring: Shadow of the Erdtree; Cuphead: The Delicious Last Course; Resident Evil 4 Remake: Separate Ways |
| Casi full DLC | Age of Empires II, Age of Empires II: Definitive Edition, Kingdom Two Crowns, Placid Plastic Duck Simulator |
| DLC propio sin detalle fino | Dead Cells, This War of Mine, XCOM: Enemy Unknown, XCOM 2 |
| Excepción | Fallout 76 no queda marcado como full DLC |

## Cambio técnico

Se amplió `dlcInfo` para evitar inventar conteos exactos cuando el dato viene como declaración manual general. La ficha dinámica ahora muestra `ownershipStatus`, `ownershipSummary` y notas faltantes.

## Pendientes

- Descargar assets oficiales de los cuatro juegos nuevos.
- Auditar exactamente qué DLC falta en Age of Empires II, Kingdom Two Crowns y Placid Plastic Duck Simulator.
- Detallar si Dead Cells, This War of Mine y XCOM están full DLC o solo tienen DLC parciales.

_Generado: `2026-05-11T04:57:26Z`._
