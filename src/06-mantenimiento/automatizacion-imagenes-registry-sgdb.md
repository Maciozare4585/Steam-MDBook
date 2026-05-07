# 🖼️ Automatización de imágenes — Registry + SteamGridDB

Esta versión usa el **Cambio B**:

```text
Juego -> Steam App ID -> steam-games-registry.json -> imágenes por ID -> páginas mdBook
```

## Archivos principales

| Archivo | Función |
|---|---|
| `data/steam-image-targets.json` | Entrada manual/base de juegos objetivo |
| `data/steam-appid-overrides.json` | Correcciones manuales por `slug` |
| `data/steam-games-registry.json` | Registro maestro con todos los IDs resueltos |
| `data/steam-assets-report.csv` | Reporte revisable en Excel/VS Code |
| `scripts/sync-game-registry-and-assets.ps1` | Script principal |
| `src/assets/games/<steamAppId>/` | Carpeta canónica de imágenes por ID |

## Imágenes por ID

Ejemplo para Elden Ring:

```text
src/assets/games/1245620/steam-header.jpg
src/assets/games/1245620/steam-capsule.jpg
src/assets/games/1245620/steam-background.jpg
src/assets/games/1245620/sgdb-hero.webp
src/assets/games/1245620/sgdb-grid.webp
```

## Solo Steam Store

```powershell
.\scripts\sync-game-registry-and-assets.ps1 -UpdateMarkdownPages
```

## SteamGridDB primero, Steam fallback

Necesitas API key de SteamGridDB.

### Opción A — variable de entorno

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"
.\scripts\sync-game-registry-and-assets.ps1 -PreferSteamGridDb -UpdateMarkdownPages
```

### Opción B — parámetro

```powershell
.\scripts\sync-game-registry-and-assets.ps1 -SteamGridDbApiKey "TU_API_KEY" -PreferSteamGridDb -UpdateMarkdownPages
```

## Descubrir juegos desde Markdown

```powershell
.\scripts\sync-game-registry-and-assets.ps1 -DiscoverFromMarkdown -PreferSteamGridDb -UpdateMarkdownPages
```

## Galería generada

El script genera/actualiza:

```text
src/05-juegos-clave/galeria-assets-generada.md
```

## Revisión recomendada

Después de correr el script, revisa:

```text
data/steam-assets-report.csv
```

Pon atención a:

```text
matchType = storesearch-first
success = false
preferredImageSource = steam
```

`storesearch-first` significa que el script tomó el primer resultado de búsqueda y conviene validarlo.

## Cómo corregir un ID mal detectado

Edita:

```text
data/steam-appid-overrides.json
```

Ejemplo:

```json
{
  "mage-arena": 3716600
}
```

Luego vuelve a correr:

```powershell
.\scripts\sync-game-registry-and-assets.ps1 -PreferSteamGridDb -UpdateMarkdownPages
```
