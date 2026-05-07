# Steam High Family mdBook — README operativo

README de comandos del proyecto. Está pensado para resolver rápido estas tareas:

- ejecutar el mdBook;
- sincronizar Steam IDs;
- descargar imágenes;
- regenerar páginas/metadatos;
- regenerar tooltips;
- reparar rutas/sidebar;
- diagnosticar juegos sin ID, sin imagen o sin tooltip.

> Este README no contiene changelog. El historial de versiones debe vivir dentro del mdBook, en la sección de mantenimiento correspondiente.

---

## 0. Regla base: ejecutar desde la raíz

Casi todos los comandos asumen que estás parado en la raíz del proyecto:

```text
book.toml
data\
scripts\
src\
theme\
```

Verifica tu ubicación:

```powershell
Get-Location
```

Si estás dentro de `src`, sube un nivel:

```powershell
cd ..
```

Confirma que ves las carpetas principales:

```powershell
Get-ChildItem
```

---

## 1. Preparación de PowerShell

Ejecutar una vez por sesión de PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Get-ChildItem .\scripts\*.ps1 | Unblock-File
```

---

## 2. Comandos rápidos por tarea

| Quiero... | Comando recomendado |
|---|---|
| Abrir el mdBook local | `mdbook serve --open` |
| Abrirlo para la red local | `mdbook serve -n 0.0.0.0 -p 3000` |
| Construir el sitio estático | `mdbook build` |
| Limpiar build/cache local | `mdbook clean` |
| Correr casi todo el pipeline | `.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -ValidatePaths` |
| Resolver Steam IDs | `.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown` |
| Descubrir juegos raros/ZZZ/MRD | `.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -DelayMs 2500` |
| Proponer candidatos fuzzy sin aprobarlos | `.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -DelayMs 2500` |
| Descargar imágenes de Steam | `.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages` |
| Regenerar páginas de juegos | `.\scripts\04-generate-game-pages.ps1` |
| Regenerar tooltips | `.\scripts\07-generate-collection-tooltips.ps1` |
| Generar galería de assets | `.\scripts\10-generate-assets-gallery.ps1` |
| Reparar páginas auxiliares | `.\scripts\09-repair-mdbook-pages.ps1` |
| Limpiar sidebar de juegos | `.\scripts\11-sanitize-games-summary.ps1` |
| Validar rutas | `.\scripts\99-validate-project-paths.ps1 -Strict` |

---

## 3. Ejecutar el mdBook

### 3.1 Abrir localmente

```powershell
mdbook serve --open
```

Wrapper disponible:

```powershell
.\scripts\serve.ps1
```

### 3.2 Abrir para celulares/PCs de la red local

```powershell
mdbook serve -n 0.0.0.0 -p 3000
```

Desde otro dispositivo conectado a la misma red:

```text
http://IP_DE_TU_PC:3000
```

Obtener IP local:

```powershell
ipconfig
```

Busca `Dirección IPv4`, por ejemplo:

```text
192.168.1.75
```

URL resultante:

```text
http://192.168.1.75:3000
```

### 3.3 Permitir puerto en firewall

Solo si otro dispositivo no puede entrar:

```powershell
New-NetFirewallRule `
  -DisplayName "mdBook Local Server 3000" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 3000 `
  -Action Allow
```

---

## 4. Build, clean y caché

### 4.1 Build estático

```powershell
mdbook build
```

Wrapper:

```powershell
.\scripts\build.ps1
```

### 4.2 Limpiar y servir otra vez

```powershell
mdbook clean
mdbook serve --open
```

### 4.3 Si el navegador muestra datos viejos

Después de `mdbook clean` y `mdbook serve --open`, usa:

```text
Ctrl + F5
```

---

## 5. Pipelines principales

### 5.1 Pipeline normal recomendado

Úsalo cuando agregaste juegos, modificaste colecciones o quieres refrescar el proyecto de forma normal.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Get-ChildItem .\scripts\*.ps1 | Unblock-File

.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -ValidatePaths
mdbook serve --open
```

### 5.2 Pipeline manual completo

Útil cuando quieres ver cada fase por separado.

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
.\scripts\10-generate-assets-gallery.ps1
.\scripts\09-repair-mdbook-pages.ps1
.\scripts\11-sanitize-games-summary.ps1
.\scripts\99-validate-project-paths.ps1 -Strict
mdbook serve --open
```

### 5.3 Pipeline para juegos nuevos

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
.\scripts\10-generate-assets-gallery.ps1
mdbook serve --open
```

### 5.4 Pipeline para `ZZZ) El Pozo` y `ZZZ) MRD`

Estas secciones suelen tener juegos raros, demos, shovelware, freebies o nombres difíciles. Usa más delay y búsqueda flexible.

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -DelayMs 2500
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages -DelayMs 2500
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

Después revisa pendientes:

```powershell
Invoke-Item .\data\steam-games-review-needed.json
Invoke-Item .\data\steam-games-retry-needed.json
```

### 5.5 Pipeline con SteamGridDB

Configura API key:

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"
```

Luego corre:

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -UseSteamGridDb -ValidatePaths
mdbook serve --open
```

Pipeline agresivo con SteamGridDB:

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"

.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -UseSteamGridDb `
  -RefreshMetadata `
  -RefreshAssets `
  -RefreshSteamGridDb `
  -ValidatePaths

mdbook serve --open
```

---

## 6. Dependencias de tooltip, imagen y metadata

Un juego tiene tooltip/preview en colección solo si se cumple esta cadena:

```text
Markdown con nombre del juego
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
src\07-juegos\por-letra\...
  ↓
07-generate-collection-tooltips.ps1
  ↓
tabla con game-hover + preview
```

Si un juego no tiene tooltip, normalmente falta una de estas tres cosas:

1. no existe en `data\steam-games-registry.json`;
2. existe, pero no tiene `steamAppId`;
3. tiene ID, pero no tiene `steam-header.jpg` descargado.

Flujo de reparación:

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -RefreshMetadata
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook clean
mdbook serve --open
```

---

## 7. Overrides manuales de Steam App ID

Cuando Steam Search no encuentra un juego, o lo detecta mal, corrige manualmente este archivo:

```text
data\steam-appid-overrides.json
```

Formato:

```json
{
  "dead-as-disco": 123456,
  "nombre-del-juego": 987654
}
```

Después de guardar el override:

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -RefreshMetadata
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

---

## 8. Referencia de scripts principales

### 8.1 `05-run-full-sync.ps1` — orquestador principal

Comando base:

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown
```

Variantes útiles:

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -ValidatePaths
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -RefreshMetadata -RefreshAssets
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -ForceSearch
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -UseSteamGridDb
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -AllowFuzzy
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -AllowFuzzy -AcceptFuzzyMatches
```

Parámetros:

| Parámetro | Uso |
|---|---|
| `-DiscoverFromMarkdown` | Descubre juegos leyendo tablas Markdown. |
| `-UseSteamGridDb` | Usa SteamGridDB además de Steam. |
| `-SteamGridDbApiKey` | API key explícita. Default: `$env:STEAMGRIDDB_API_KEY`. |
| `-RefreshMetadata` | Reconsulta metadatos aunque existan. |
| `-RefreshAssets` | Redescarga assets de Steam. |
| `-RefreshSteamGridDb` | Redescarga assets de SteamGridDB. |
| `-ForceSearch` | Fuerza búsqueda de IDs. |
| `-AllowFuzzy` | Permite obtener candidatos fuzzy, pero no los aprueba solo. |
| `-AcceptFuzzyMatches` | Acepta candidatos fuzzy y los escribe al registry; usar solo después de revisar. |
| `-SkipCollectionTooltips` | Omite tooltips de tablas. |
| `-ValidatePaths` | Ejecuta validación de rutas. |

Wrappers equivalentes:

```powershell
.\scripts\sync-game-registry-and-assets.ps1 -DiscoverFromMarkdown
.\scripts\sync-steam-assets.ps1 -DiscoverFromMarkdown
```

CMD:

```cmd
scripts\run-full-sync.cmd -DiscoverFromMarkdown
```

---

### 8.2 `01-sync-steam-ids.ps1` — resolver Steam IDs

Comandos:

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -RefreshMetadata
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -ForceSearch
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -DelayMs 2500
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -AcceptFuzzyMatches -DelayMs 2500
```

Cambiar país/idioma:

```powershell
.\scripts\01-sync-steam-ids.ps1 `
  -DiscoverFromMarkdown `
  -CountryCode "mx" `
  -Language "spanish"
```

CMD:

```cmd
scripts\run-sync-ids.cmd -DiscoverFromMarkdown
```

Archivos que actualiza:

```text
data\steam-games-registry.json
data\steam-image-targets.json
data\steam-games-review-needed.json
data\steam-games-retry-needed.json
```

Parámetros:

| Parámetro | Uso |
|---|---|
| `-TargetsPath` | Ruta de `steam-image-targets.json`. |
| `-OverridesPath` | Ruta de `steam-appid-overrides.json`. |
| `-RegistryPath` | Ruta de `steam-games-registry.json`. |
| `-ReviewPath` | Ruta de `steam-games-review-needed.json`. |
| `-RetryPath` | Ruta de `steam-games-retry-needed.json`. |
| `-DiscoverFromMarkdown` | Descubre títulos desde Markdown. |
| `-UpdateTargets` | Actualiza `steam-image-targets.json`. Default activo. |
| `-AllowFuzzy` | Permite obtener candidatos no exactos. Desde V6.5.14 se mandan a revisión por default. |
| `-AcceptFuzzyMatches` | Aprueba candidatos fuzzy y los escribe al registry; debe usarse con cuidado. |
| `-OnlyMissing` | Prioriza faltantes. Default activo. |
| `-RefreshMetadata` | Reconsulta metadatos. |
| `-ForceSearch` | Fuerza búsqueda. |
| `-DelayMs` | Pausa entre llamadas. Default: `1200`. |
| `-CountryCode` | País para Store Search. Default: `us`. |
| `-Language` | Idioma. Default: `english`. |

---

### 8.3 `02-download-steam-images.ps1` — descargar imágenes de Steam

Comandos:

```powershell
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages -RefreshAssets
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages -WhatIfMode
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages -DelayMs 2500
```

CMD:

```cmd
scripts\run-download-images.cmd -UpdateMarkdownPages
```

Salida principal:

```text
src\assets\games\<steamAppId>\
data\steam-assets-report.csv
data\steam-assets-report.json
```

Parámetros:

| Parámetro | Uso |
|---|---|
| `-RegistryPath` | Registry de juegos. |
| `-ReportCsvPath` | Reporte CSV. |
| `-ReportJsonPath` | Reporte JSON. |
| `-RetryPath` | Archivo de reintentos. |
| `-ReviewPath` | Archivo de revisión. |
| `-UpdateMarkdownPages` | Actualiza Markdown relacionado. |
| `-WhatIfMode` | Simulación. |
| `-RefreshAssets` | Redescarga assets. |
| `-DelayMs` | Delay entre llamadas. Default: `1200`. |
| `-Language` | Idioma. Default: `english`. |

---

### 8.4 `03-sync-steamgriddb-assets.ps1` — assets de SteamGridDB

Configurar API key:

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"
```

Comandos:

```powershell
.\scripts\03-sync-steamgriddb-assets.ps1 -UpdateMarkdownPages
.\scripts\03-sync-steamgriddb-assets.ps1 -UpdateMarkdownPages -PreferAnimated
.\scripts\03-sync-steamgriddb-assets.ps1 -UpdateMarkdownPages -RefreshSteamGridDb
.\scripts\03-sync-steamgriddb-assets.ps1 -UpdateMarkdownPages -WhatIfMode
.\scripts\03-sync-steamgriddb-assets.ps1 -UpdateMarkdownPages -DelayMs 1000
```

Parámetros:

| Parámetro | Uso |
|---|---|
| `-RegistryPath` | Registry de juegos. |
| `-SteamGridDbApiKey` | API key. Default: `$env:STEAMGRIDDB_API_KEY`. |
| `-PreferAnimated` | Prefiere assets animados. Default activo. |
| `-UpdateMarkdownPages` | Actualiza Markdown relacionado. |
| `-WhatIfMode` | Simulación. |
| `-RefreshSteamGridDb` | Redescarga assets. |
| `-DelayMs` | Delay entre llamadas. Default: `350`. |

---

### 8.5 `04-generate-game-pages.ps1` — juegos/metadatos

Regenera la sección compacta por letra desde el registry:

```powershell
.\scripts\04-generate-game-pages.ps1
```

Páginas individuales, normalmente no recomendado porque puede ensuciar el sidebar:

```powershell
.\scripts\04-generate-game-pages.ps1 -IncludeIndividualPages
```

Parámetros:

| Parámetro | Uso |
|---|---|
| `-RegistryPath` | Registry de juegos. |
| `-OutDir` | Carpeta de salida. Default: `src\07-juegos`. |
| `-DataOutDir` | Salida de `games-index.json`. Default: `src\assets\data`. |
| `-IncludeIndividualPages` | Genera páginas individuales. |

---

### 8.6 `07-generate-collection-tooltips.ps1` — tooltips de tablas

```powershell
.\scripts\07-generate-collection-tooltips.ps1
```

Parámetros:

| Parámetro | Uso |
|---|---|
| `-RegistryPath` | Registry de juegos. |
| `-MarkdownRoots` | Raíces donde se aplican tooltips. Default: `src\02-colecciones`, `src\03-estados`, `src\04-decision`, `src\05-perfiles`. |

---

### 8.7 Scripts auxiliares

| Script | Comando | Uso |
|---|---|---|
| Galería de assets | `.\scripts\10-generate-assets-gallery.ps1` | Genera `src\07-juegos\galeria-assets-generada.md`. |
| Sanitizar sidebar | `.\scripts\11-sanitize-games-summary.ps1` | Evita que el sidebar liste cientos de juegos. |
| Reparar páginas | `.\scripts\09-repair-mdbook-pages.ps1` | Repara páginas auxiliares e inconsistencias básicas. |
| Inventario local de assets | `.\scripts\08-export-local-assets-inventory.ps1` | Exporta `data\local-assets-existing.csv`. |
| Validar rutas | `.\scripts\99-validate-project-paths.ps1` | Valida rutas internas. |
| Validar rutas estricto | `.\scripts\99-validate-project-paths.ps1 -Strict` | Validación más agresiva. |
| Fichas clave Daniel | `.\scripts\06-update-key-game-pages.ps1` | Actualiza fichas base de Daniel. |
| Fichas extendidas Daniel | `.\scripts\13-generate-extended-key-sheets.ps1` | Genera fichas extendidas. |
| Activar imágenes antiguas | `.\scripts\activate-downloaded-images.ps1` | Script legado para assets por slug. |

Parámetros de scripts auxiliares:

| Script | Parámetros relevantes |
|---|---|
| `10-generate-assets-gallery.ps1` | `-RegistryPath`, `-OutPath` |
| `11-sanitize-games-summary.ps1` | `-SummaryPath`, `-RegistryPath` |
| `09-repair-mdbook-pages.ps1` | `-RegistryPath`, `-TargetsPath`, `-ReviewPath`, `-RetryPath`, `-IgnoredPath`, `-GamesOutDir` |
| `08-export-local-assets-inventory.ps1` | `-AssetsRoot`, `-OutPath` |
| `06-update-key-game-pages.ps1` | `-RegistryPath`, `-GamesKeyPath`, `-KeyDir` |
| `13-generate-extended-key-sheets.ps1` | `-DataPath`, `-OutPath`, `-IndexPath` |

---

## 9. Diagnósticos

### 9.1 Juegos sin `steamAppId`

```powershell
Get-Content .\data\steam-games-registry.json |
  ConvertFrom-Json |
  Where-Object { -not $_.steamAppId } |
  Sort-Object title |
  Select-Object title, slug, steamAppId, officialName, steamType |
  Format-Table -AutoSize
```

Exportar a CSV:

```powershell
Get-Content .\data\steam-games-registry.json |
  ConvertFrom-Json |
  Where-Object { -not $_.steamAppId } |
  Sort-Object title |
  Select-Object title, slug, steamAppId, officialName, steamType |
  Export-Csv .\data\juegos-sin-steamid.csv -NoTypeInformation -Encoding UTF8

Invoke-Item .\data\juegos-sin-steamid.csv
```

### 9.2 Pendientes de revisión/reintento

```powershell
Get-Content .\data\steam-games-review-needed.json | ConvertFrom-Json | Format-Table -AutoSize
Get-Content .\data\steam-games-retry-needed.json  | ConvertFrom-Json | Format-Table -AutoSize
```

Abrir archivos:

```powershell
Invoke-Item .\data\steam-games-review-needed.json
Invoke-Item .\data\steam-games-retry-needed.json
```

### 9.3 Buscar juego específico

```powershell
$game = "Dead as Disco"

Get-Content .\data\steam-games-registry.json |
  ConvertFrom-Json |
  Where-Object { $_.title -like "*$game*" -or $_.officialName -like "*$game*" } |
  Format-List
```

Buscar en review/retry:

```powershell
$game = "Dead as Disco"

Get-Content .\data\steam-games-review-needed.json |
  ConvertFrom-Json |
  Where-Object { $_.title -like "*$game*" -or $_.detectedName -like "*$game*" } |
  Format-List

Get-Content .\data\steam-games-retry-needed.json |
  ConvertFrom-Json |
  Where-Object { $_.title -like "*$game*" -or $_.detectedName -like "*$game*" } |
  Format-List
```

### 9.4 Juegos con ID pero sin imagen

```powershell
$registry = Get-Content .\data\steam-games-registry.json | ConvertFrom-Json

$registry |
  Where-Object { $_.steamAppId } |
  Where-Object {
    -not (Test-Path ".\src\assets\games\$($_.steamAppId)\steam-header.jpg")
  } |
  Sort-Object title |
  Select-Object title, steamAppId, officialName |
  Format-Table -AutoSize
```

Exportar a CSV:

```powershell
$registry = Get-Content .\data\steam-games-registry.json | ConvertFrom-Json

$registry |
  Where-Object { $_.steamAppId } |
  Where-Object {
    -not (Test-Path ".\src\assets\games\$($_.steamAppId)\steam-header.jpg")
  } |
  Sort-Object title |
  Select-Object title, steamAppId, officialName |
  Export-Csv .\data\juegos-con-id-sin-imagen.csv -NoTypeInformation -Encoding UTF8

Invoke-Item .\data\juegos-con-id-sin-imagen.csv
```

---

## 10. Reparación por síntoma

| Síntoma | Causa probable | Comando |
|---|---|---|
| Juego nuevo sin tooltip | Falta ID, imagen o regenerar tooltip | Ver sección `6`. |
| Juego en ZZZ sin imagen | No tiene `steamAppId` o no se descargó asset | Pipeline `5.4`. |
| Dead as Disco no aparece con hover | Falta override/ID o rerun de tooltips | Sección `7` + pipeline `5.3`. |
| Sidebar de juegos gigante | `SUMMARY.md` volvió a listar juegos individuales | `.\scripts\11-sanitize-games-summary.ps1` |
| `mdbook serve` marca páginas faltantes | Links o páginas auxiliares faltantes | `.\scripts\09-repair-mdbook-pages.ps1` |
| Imágenes existen pero no se ven | Caché/build viejo | `mdbook clean`, regenerar páginas, `Ctrl + F5`. |
| Rate limit / `429` | Muchas llamadas seguidas | Usar `-DelayMs 2500` y revisar `steam-games-retry-needed.json`. |
| Steam Search detecta mal un juego | Match incorrecto | Agregar override en `steam-appid-overrides.json`. |

Comandos de reparación frecuentes:

```powershell
.\scripts\09-repair-mdbook-pages.ps1
.\scripts\11-sanitize-games-summary.ps1
.\scripts\99-validate-project-paths.ps1 -Strict
mdbook serve --open
```

Imágenes no visibles aunque ya existen:

```powershell
mdbook clean
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

Luego:

```text
Ctrl + F5
```

---

## 11. Archivos principales

| Archivo | Uso |
|---|---|
| `book.toml` | Configuración principal de mdBook. |
| `src\SUMMARY.md` | Sidebar/índice del mdBook. |
| `data\steam-games-registry.json` | Registro maestro de juegos, IDs y metadata. |
| `data\steam-image-targets.json` | Targets para imágenes. |
| `data\steam-appid-overrides.json` | Overrides manuales de Steam App ID. |
| `data\steam-games-review-needed.json` | Juegos que requieren revisión manual. |
| `data\steam-games-retry-needed.json` | Juegos para reintentar por error/rate limit. |
| `data\steam-assets-report.csv` | Reporte CSV de assets descargados. |
| `data\steam-assets-report.json` | Reporte JSON de assets descargados. |
| `data\local-assets-existing.csv` | Inventario local de assets existentes. |

---

## 12. Carpetas principales

| Carpeta | Uso |
|---|---|
| `src\` | Contenido Markdown del mdBook. |
| `src\02-colecciones\` | Colecciones globales, técnicas y cuarentena. |
| `src\05-perfiles\` | Perfiles personales: Daniel, Jesse y Jovan. |
| `src\07-juegos\` | Índice compacto, metadatos y galería de juegos. |
| `src\assets\games\<steamAppId>\` | Imágenes por juego. |
| `scripts\` | Automatización del proyecto. |
| `theme\` | CSS y JavaScript personalizado. |
| `data\` | Registry, reportes, overrides y data auxiliar. |

---

## 13. Orden recomendado según cambio

### Solo quiero ver el sitio

```powershell
mdbook serve --open
```

### Cambié texto normal del mdBook

```powershell
mdbook serve --open
```

### Agregué un juego nuevo a una colección

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

### Agregué muchos juegos raros, ZZZ o MRD

```powershell
.\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown -AllowFuzzy -DelayMs 2500
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages -DelayMs 2500
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

### Solo quiero imágenes

```powershell
.\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages
```

### Solo quiero tooltips

```powershell
.\scripts\07-generate-collection-tooltips.ps1
```

### Solo quiero regenerar juegos/metadatos

```powershell
.\scripts\04-generate-game-pages.ps1
```

### Quiero validar/reparar lo básico

```powershell
.\scripts\09-repair-mdbook-pages.ps1
.\scripts\11-sanitize-games-summary.ps1
.\scripts\99-validate-project-paths.ps1 -Strict
mdbook serve --open
```

### Quiero correr casi todo

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -ValidatePaths
mdbook serve --open
```


---

## Git / versionado

Este paquete incluye configuración base para Git: `.gitignore`, `.gitattributes` y `.editorconfig`.

Guía rápida: [`docs/git-workflow.md`](docs/git-workflow.md)
