# Steam High Family mdBook — README operativo

README de uso rápido para levantar, sincronizar, enriquecer y mantener el mdBook de la biblioteca familiar de Steam.

> Este README es operativo. El changelog/versionado histórico debe vivir dentro del mdBook, en `src/06-mantenimiento/` o la sección equivalente.

---

## 0. Estructura esperada

Ejecuta los comandos desde la raíz del proyecto, donde existen estas rutas:

```text
book.toml
data\
docs\
scripts\
src\
theme\
```

Verifica ubicación:

```powershell
Get-Location
Get-ChildItem
```

Si estás dentro de `src`, sube un nivel:

```powershell
cd ..
```

---

## 1. Preparación de PowerShell

Ejecuta una vez por sesión:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Get-ChildItem .\scripts\*.ps1 | Unblock-File
```

---

## 2. Comandos rápidos

| Quiero... | Comando recomendado |
|---|---|
| Abrir el mdBook local | `mdbook serve --open` |
| Abrirlo para la red local | `mdbook serve -n 0.0.0.0 -p 3000` |
| Construir el sitio estático | `mdbook build` |
| Limpiar build/cache local | `mdbook clean` |
| Correr pipeline normal | `.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -ValidatePaths` |
| Resolver Steam IDs | `.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown` |
| Proponer matches fuzzy sin aprobarlos | `.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -DelayMs 2500` |
| Descargar imágenes de Steam | `.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages` |
| Regenerar páginas de juegos | `.\scripts\04-generate-game-pages.ps1` |
| Generar metadata base | `.\scripts\14-generate-games-metadata-base.ps1` |
| Regenerar `games-index.json` con metadata | `.\scripts\15-build-games-index-with-metadata.ps1` |
| Enriquecer metadata desde Steam | `.\scripts\17-enrich-steam-metadata.ps1 -MaxGames 100 -DelayMs 2000 -BuildIndexAfter` |
| Sincronizar catálogo DLC | `.\scripts\18-sync-steam-dlc.ps1 -MaxGames 50 -DelayMs 2000 -BuildIndexAfter` |
| Regenerar tooltips | `.\scripts\07-generate-collection-tooltips.ps1` |
| Generar galería de assets | `.\scripts\10-generate-assets-gallery.ps1` |
| Reparar páginas auxiliares | `.\scripts\09-repair-mdbook-pages.ps1` |
| Limpiar sidebar de juegos | `.\scripts\11-sanitize-games-summary.ps1` |
| Validar rutas | `.\scripts\99-validate-project-paths.ps1 -Strict` |

---

## 3. Levantar el mdBook

### 3.1 Local

```powershell
mdbook serve --open
```

Wrappers disponibles, si existen:

```powershell
.\scripts\serve.ps1
.\scripts\build.ps1
```

### 3.2 Red local / celular

```powershell
mdbook serve -n 0.0.0.0 -p 3000
```

Obtén tu IP local:

```powershell
ipconfig
```

En otro dispositivo de la misma red abre:

```text
http://IP_DE_TU_PC:3000
```

Si Windows bloquea el puerto:

```powershell
New-NetFirewallRule `
  -DisplayName "mdBook Local Server 3000" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 3000 `
  -Action Allow
```

### 3.3 Limpiar caché

```powershell
mdbook clean
mdbook build
mdbook serve --open
```

En navegador:

```text
Ctrl + F5
```

---

## 4. Pipelines principales

### 4.1 Pipeline normal recomendado

Úsalo cuando agregaste juegos a colecciones, corregiste Markdown o quieres regenerar lo básico.

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -ValidatePaths
mdbook serve --open
```

### 4.2 Pipeline completo recomendado

Incluye Steam IDs, assets, metadata extendida y catálogo DLC.

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -AllowFuzzy `
  -ValidatePaths `
  -EnrichSteamMetadata `
  -MetadataMaxGames 100 `
  -MetadataDelayMs 2000 `
  -SyncSteamDlc `
  -DlcMaxGames 100 `
  -DlcDelayMs 2000

mdbook clean
mdbook build
mdbook serve --open
```

### 4.3 Pipeline pesado / todos los pendientes

Úsalo con calma. Puede tardar mucho.

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -AllowFuzzy `
  -ValidatePaths `
  -EnrichSteamMetadata `
  -MetadataDelayMs 2000 `
  -SyncSteamDlc `
  -DlcDelayMs 2000
```

### 4.4 Pipeline manual por fases

Útil para diagnosticar en qué paso falla algo.

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\04-generate-game-pages.ps1
.\scripts\14-generate-games-metadata-base.ps1
.\scripts\15-build-games-index-with-metadata.ps1
.\scripts\07-generate-collection-tooltips.ps1
.\scripts\10-generate-assets-gallery.ps1
.\scripts\09-repair-mdbook-pages.ps1
.\scripts\11-sanitize-games-summary.ps1
.\scripts\99-validate-project-paths.ps1 -Strict
mdbook serve --open
```

---

## 5. Juegos nuevos

Para agregar juegos nuevos **sin crear sección nueva**, mételos en las tablas Markdown de colecciones existentes. El pipeline detecta juegos desde tablas con columna `Juego`.

Después corre:

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -AllowFuzzy `
  -ValidatePaths

mdbook clean
mdbook serve --open
```

Si quieres traer metadata e imágenes faltantes:

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -AllowFuzzy `
  -ValidatePaths `
  -EnrichSteamMetadata `
  -MetadataMaxGames 100 `
  -MetadataDelayMs 2000
```

Evita `-AcceptFuzzyMatches` salvo que estés dispuesto a revisar App IDs incorrectos. Ese parámetro acepta matches dudosos de Steam automáticamente.

---

## 6. DLC / contenido adicional

El sistema actual usa **catálogo DLC automático + marca manual por iconos**.

### 6.1 Sincronizar catálogo DLC

Prueba inicial:

```powershell
.\scripts\18-sync-steam-dlc.ps1 -MaxGames 50 -DelayMs 2000 -BuildIndexAfter
```

Juegos concretos por AppID:

```powershell
.\scripts\18-sync-steam-dlc.ps1 -OnlyAppIds 1245620,292030,2050650 -DelayMs 2000 -BuildIndexAfter
```

Integrado al full sync:

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -SyncSteamDlc `
  -DlcMaxGames 50 `
  -DlcDelayMs 2000 `
  -ValidatePaths
```

### 6.2 Marcar DLC manualmente

Edita:

```text
data/games-metadata.json
```

Cada DLC debe usar `markers`, un arreglo de iconos. Puede llevar más de uno:

```json
"markers": ["owned", "pass"]
```

Valores sugeridos:

| Marker | Icono | Uso |
|---|---:|---|
| `owned` | ✅ | Lo tenemos. |
| `missing` | ⬜ | No lo tenemos / pendiente. |
| `skip` | 🚫 | No comprar. |
| `free` | 🆓 | Contenido gratuito. |
| `pass` | 🧩 | Season pass, expansion pass, pack grande. |
| `soundtrack` | 🎵 | Banda sonora / OST. |
| `artbook` | 📘 | Artbook / libro digital. |
| `cosmetic` | 🎨 | Skin, traje, cosmético. |
| `currency` | 💰 | Moneda, créditos, consumible. |

Ejemplo:

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

El campo legado `marker` puede existir por compatibilidad, pero el template manual debe usar `markers`. La ficha muestra solo iconos por fila; el texto queda como tooltip/accesibilidad.

Después regenera el índice:

```powershell
.\scripts\15-build-games-index-with-metadata.ps1
mdbook clean
mdbook serve --open
```

### 6.3 Inferencia automática de iconos

Si `markers` no existe, la ficha intenta inferirlo desde `marker` legado y después desde:

- `owned`
- `status`
- `isFree`
- nombre del DLC, por ejemplo `Soundtrack`, `OST`, `Artbook`, `Season Pass`, `Skin`, etc.

---

## 7. Metadata extendida

### 7.1 Generar base local

```powershell
.\scripts\14-generate-games-metadata-base.ps1
.\scripts\15-build-games-index-with-metadata.ps1
```

### 7.2 Enriquecer desde Steam Store API

```powershell
.\scripts\17-enrich-steam-metadata.ps1 -MaxGames 100 -DelayMs 2000 -BuildIndexAfter
```

Simulación:

```powershell
.\scripts\17-enrich-steam-metadata.ps1 -DryRun -MaxGames 20
```

Dentro del full sync:

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -EnrichSteamMetadata `
  -MetadataMaxGames 100 `
  -MetadataDelayMs 2000
```

> Si aparecen errores `429`, sube el delay a `2500` o `3000`.

---

## 8. Tooltips, imágenes y fichas dinámicas

Cadena necesaria para que un juego tenga tooltip, imagen y ficha:

```text
Markdown con columna Juego
  ↓
01-sync-steam-ids.ps1
  ↓
data\steam-games-registry.json con steamAppId
  ↓
02-download-steam-images.ps1
  ↓
src\assets\games\<steamAppId>\steam-header.jpg
  ↓
04-generate-game-pages.ps1
  ↓
src\assets\data\games-index.json
  ↓
07-generate-collection-tooltips.ps1
```

Reparación típica:

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -DelayMs 2500
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages -DelayMs 2500
.\scripts\04-generate-game-pages.ps1
.\scripts\15-build-games-index-with-metadata.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook clean
mdbook serve --open
```

---

## 9. SteamGridDB

Configura API key:

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"
```

Pipeline normal:

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -UseSteamGridDb -ValidatePaths
mdbook serve --open
```

Pipeline agresivo:

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -UseSteamGridDb `
  -RefreshMetadata `
  -RefreshAssets `
  -RefreshSteamGridDb `
  -ValidatePaths
```

Usa `-RefreshAssets` y `-RefreshSteamGridDb` solo cuando quieras redescargar imágenes ya existentes.

---

## 10. Overrides manuales de Steam App ID

Archivo:

```text
data/steam-appid-overrides.json
```

Formato:

```json
{
  "dead-as-disco": 123456,
  "nombre-del-juego": 987654
}
```

Después:

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -RefreshMetadata
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

---

## 11. Diagnósticos útiles

### 11.1 Juegos sin Steam App ID

```powershell
Get-Content .\data\steam-games-registry.json |
  ConvertFrom-Json |
  Where-Object { -not $_.steamAppId } |
  Sort-Object title |
  Select-Object title, slug, steamAppId, officialName, steamType |
  Format-Table -AutoSize
```

### 11.2 Pendientes de revisión/reintento

```powershell
Invoke-Item .\data\steam-games-review-needed.json
Invoke-Item .\data\steam-games-retry-needed.json
```

### 11.3 Buscar juego específico

```powershell
$game = "Dead as Disco"

Get-Content .\data\steam-games-registry.json |
  ConvertFrom-Json |
  Where-Object { $_.title -like "*$game*" -or $_.officialName -like "*$game*" } |
  Format-List
```

### 11.4 Juegos con ID pero sin imagen

```powershell
$registry = Get-Content .\data\steam-games-registry.json | ConvertFrom-Json

$registry |
  Where-Object { $_.steamAppId } |
  Where-Object { -not (Test-Path ".\src\assets\games\$($_.steamAppId)\steam-header.jpg") } |
  Sort-Object title |
  Select-Object title, steamAppId, officialName |
  Format-Table -AutoSize
```

---

## 12. CSS / colores del proyecto

Archivo principal:

```text
theme/custom.css
```

La versión documentada trae un **panel de variables** al inicio del archivo. Para cambiar colores globales, edita primero esa zona:

```css
:root {
  --steam-accent-rgb: 125, 170, 255;
  --steam-accent: rgb(var(--steam-accent-rgb));
  --steam-surface-soft: rgba(255, 255, 255, .035);
  --steam-border-soft: rgba(var(--steam-accent-rgb), .24);
}
```

### 12.1 Variables más importantes

| Variable | Controla |
|---|---|
| `--steam-accent-rgb` | Color principal del proyecto. Cambia links, bordes, callouts y botones. |
| `--steam-surface-soft` | Fondo suave de tarjetas. |
| `--steam-border-soft` | Bordes generales de cards, chips y botones. |
| `--steam-floating-bg` | Fondo del tooltip flotante de juegos. |
| `--steam-shadow-floating` | Color de sombra del tooltip flotante. |
| `--content-max-width` | Ancho máximo del contenido. |
| `--content-readable-width` | Ancho cómodo para párrafos largos. |
| `--dlc-owned-bg` | Fondo de marcador DLC `owned`. |
| `--dlc-missing-bg` | Fondo de marcador DLC `missing`. |
| `--dlc-skip-bg` | Fondo de marcador DLC `skip`. |
| `--priority-alta-bg` | Fondo de badge de prioridad alta. |
| `--profile-iconic` | Color de importancia personal `iconic`. |

### 12.2 Reglas de edición

1. Cambia primero variables en `:root`.
2. Evita editar colores sueltos dentro de componentes si ya existe una variable.
3. Para agregar un nuevo color, crea variable con nombre semántico.
4. Mantén los componentes agrupados por sección.
5. Después de editar CSS, corre:

```powershell
mdbook clean
mdbook serve --open
```

Y en navegador:

```text
Ctrl + F5
```

---

## 13. Archivos principales

| Archivo | Uso |
|---|---|
| `book.toml` | Configuración principal de mdBook. |
| `src/SUMMARY.md` | Sidebar/índice del mdBook. |
| `theme/custom.css` | Estilos, layout visual y colores. |
| `theme/game-detail.js` | Ficha dinámica de juegos. |
| `src/assets/data/games-index.json` | Índice consumido por la ficha dinámica. |
| `data/steam-games-registry.json` | Registro maestro de juegos, IDs e imágenes. |
| `data/games-metadata.json` | Metadata extendida, DLC, estados personales y reglas. |
| `data/steam-image-targets.json` | Targets para imágenes. |
| `data/steam-appid-overrides.json` | Overrides manuales de Steam App ID. |
| `data/steam-games-review-needed.json` | Juegos que requieren revisión manual. |
| `data/steam-games-retry-needed.json` | Juegos para reintentar por error/rate limit. |
| `data/dlc-sync-report.json` | Reporte de sincronización DLC. |

---

## 14. Carpetas principales

| Carpeta | Uso |
|---|---|
| `src/` | Contenido Markdown del mdBook. |
| `src/02-colecciones/` | Colecciones globales, técnicas y cuarentena. |
| `src/03-estados/` | Estados personales: terminado, sin terminar, postgame, etc. |
| `src/04-decision/` | Selectores, backlog activo y ayuda para decidir qué jugar. |
| `src/05-perfiles/` | Perfiles personales: Daniel, Jesse y Jovan. |
| `src/06-mantenimiento/` | Versiones, notas técnicas y mantenimiento. |
| `src/07-juegos/` | Índice compacto, metadata y galería de juegos. |
| `src/assets/games/<steamAppId>/` | Imágenes por juego. |
| `scripts/` | Automatización. |
| `theme/` | CSS y JavaScript personalizado. |
| `data/` | Registry, metadata, reportes, overrides y data auxiliar. |

---

## 15. Git / versionado

Este paquete debe ignorar builds y assets pesados generados.

Revisa:

```text
.gitignore
.gitattributes
.editorconfig
```

Guía rápida, si existe:

```text
docs/git-workflow.md
```
