# Automatización de imágenes de Steam

Esta carpeta mdBook incluye una automatización para descargar imágenes de Steam a partir de `steamAppId`.

## Archivos

| Archivo | Función |
|---|---|
| `data/steam-image-targets.json` | Lista de juegos objetivo |
| `data/steam-appid-overrides.json` | App IDs conocidos por `slug` |
| `scripts/sync-steam-assets.ps1` | Descarga assets desde Steam |
| `scripts/activate-downloaded-images.ps1` | Activa imágenes en fichas clave |
| `data/steam-assets-report.csv` | Reporte generado |
| `data/steam-assets-report.json` | Reporte generado |

## Uso recomendado

Desde la raíz del mdBook:

```powershell
.\scripts\sync-steam-assets.ps1 -UpdateMarkdownPages
```

Luego ejecuta:

```powershell
mdbook serve --open
```

## Modo full automático

Para que el script también intente descubrir juegos desde los Markdown:

```powershell
.\scripts\sync-steam-assets.ps1 -DiscoverFromMarkdown -UpdateMarkdownPages
```

## Búsqueda automática

Esta versión usa `https://store.steampowered.com/api/storesearch/` cuando falta `steamAppId`.

## Simular sin descargar

```powershell
.\scripts\sync-steam-assets.ps1 -WhatIfMode
```

## Dónde quedan las imágenes

```text
src/assets/games/<slug>/header.jpg
src/assets/games/<slug>/capsule.jpg
src/assets/games/<slug>/background.jpg
```

## Qué hacer cuando falle un juego

Agrega manualmente su `appId` en `data/steam-image-targets.json` o en `data/steam-appid-overrides.json`.

Ejemplo:

```json
{
  "elden-ring": 1245620,
  "nier-automata": 524220
}
```

## Nota

El endpoint `appdetails` de Steam Store puede devolver apps que no son juegos, demos o elementos raros.
Por eso el script genera reporte para revisar coincidencias ambiguas.
