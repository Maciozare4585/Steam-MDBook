# 🧼 V6.4 — Registry limpio y pipeline separado

Esta versión separa el flujo en scripts pequeños y evita contaminar el registry con falsos positivos.

## Arquitectura

```text
steam-image-targets.json
        ↓
01-sync-steam-ids.ps1
        ↓
steam-games-registry.json       steam-games-review-needed.json
        ↓
02-download-steam-images.ps1
        ↓
src/assets/games/<steamAppId>/
        ↓
03-sync-steamgriddb-assets.ps1
        ↓
04-generate-game-pages.ps1
        ↓
src/07-juegos/
```

## Archivos principales

| Archivo | Función |
|---|---|
| `data/steam-games-registry.json` | Registro aprobado y limpio |
| `data/steam-games-review-needed.json` | Matches dudosos o no encontrados |
| `data/steam-games-ignored.json` | Encabezados/basura ignorada |
| `data/steam-appid-overrides.json` | Correcciones manuales por slug |
| `data/steam-image-targets.json` | Lista base de juegos a resolver |
| `src/07-juegos/index.md` | Índice visual/clickable generado |
| `src/07-juegos/<steamAppId>.md` | Página genérica del juego |

## Scripts

### 1. Actualizar IDs

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -UpdateTargets
```

Modo estricto:
- acepta `provided`, `override` y `storesearch-exact`;
- manda `contains`, `first`, `not-found`, encabezados y rarezas a revisión.

### 2. Descargar imágenes oficiales de Steam

```powershell
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
```

Guarda imágenes por ID:

```text
src/assets/games/<steamAppId>/steam-header.jpg
src/assets/games/<steamAppId>/steam-capsule.jpg
src/assets/games/<steamAppId>/steam-background.jpg
```

### 3. Descargar SteamGridDB

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"
.\scripts\03-sync-steamgriddb-assets.ps1 -UpdateMarkdownPages
```

Si encuentra assets, guarda:

```text
src/assets/games/<steamAppId>/sgdbHero.webp
src/assets/games/<steamAppId>/sgdbGrid.webp
src/assets/games/<steamAppId>/sgdbLogo.png
```

### 4. Generar páginas genéricas

```powershell
.\scripts\04-generate-game-pages.ps1
```

### 5. Todo junto

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown
```

Con SteamGridDB:

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -UseSteamGridDb
```

Desde CMD:

```cmd
scripts\run-full-sync.cmd -DiscoverFromMarkdown
```

## Por qué página genérica y no tooltip

Tooltip sirve para una nota corta, pero no para metadatos reales.
La estrategia elegida es:

```text
click en juego -> página genérica -> imagen + Steam App ID + rutas + metadata
```

Eso es más estable, navegable, compatible con mdBook y exportable.

## Estado inicial de limpieza

- Registry aprobado: **664** entradas.
- Revisión pendiente: **69** entradas.
- Ignoradas: **5** entradas.
