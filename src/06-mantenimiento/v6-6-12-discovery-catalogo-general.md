# V6.6.12 · Discovery reset y catálogo general

## Objetivo

Reparar el flujo donde la lista general de juegos dependía casi por completo de `steam-games-registry.json`.

Ese enfoque ocultaba entradas presentes en colecciones Markdown cuando todavía no tenían `steamAppId`, como:

- externos/no-Steam;
- demos, betas, benchmarks y test servers;
- herramientas/apps;
- entradas de `ZZZ) El Pozo` y `ZZZ) MRD` aún no resueltas;
- títulos que requieren revisión manual u override.

## Cambios técnicos

- Se agregó `scripts/00-reset-discovery-state.ps1`.
- Se agregó `scripts/19-build-library-catalog.ps1`.
- `Get-MarkdownTargets` ahora detecta columnas `Juego` y `Elemento`.
- El discovery ahora prioriza archivos activos enlazados desde `src/SUMMARY.md` y excluye mantenimiento/juegos generados.
- `01-sync-steam-ids.ps1` ya no borra targets sin AppID al reescribir `steam-image-targets.json`.
- `04-generate-game-pages.ps1` usa `data/library-catalog.json` para el índice general.
- `11-sanitize-games-summary.ps1` usa `data/library-catalog.json` para calcular letras visibles.
- Se reiniciaron `steam-games-review-needed.json`, `steam-games-retry-needed.json` y `steam-games-ignored.json` en esta versión base.

## Archivos nuevos

```txt
scripts/00-reset-discovery-state.ps1
scripts/19-build-library-catalog.ps1
data/library-discovered-targets.json
data/library-catalog.json
src/assets/data/library-catalog.json
data/discovery-reset-report.json
data/library-catalog-report.json
```

## Resultado en esta generación

```txt
Registry Steam         : 972
Targets reconstruidos : 1116
Catálogo general      : 1116
Con Steam App ID      : 972
Sin App ID / catálogo : 144
```

## Flujo recomendado

```powershell
.\scripts\00-reset-discovery-state.ps1 -GenerateExternalGames
.\scripts\19-build-library-catalog.ps1
.\scripts\04-generate-game-pages.ps1
.\scripts\11-sanitize-games-summary.ps1
mdbook clean
mdbook build
mdbook serve --open
```

Después, para resolver AppIDs faltantes:

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -UpdateTargets
.\scripts\19-build-library-catalog.ps1
.\scripts\04-generate-game-pages.ps1
```

## Nota

`steam-games-registry.json` sigue siendo la fuente de juegos Steam confirmados.  
`library-catalog.json` es la lista general completa del mdBook, incluyendo entradas todavía no resueltas contra Steam.
