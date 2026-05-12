# V6.6.6 — Catálogo DLC desde Steam

## Objetivo

Agregar una capa automática para detectar los DLC disponibles de cada juego desde Steam y mostrarlos en la ficha dinámica como una tabla controlada desde `data/games-metadata.json`.

## Cambio principal

Se agregó el script:

```powershell
.\scripts\18-sync-steam-dlc.ps1
```

Este script:

1. Lee `data/games-metadata.json`.
2. Consulta Steam Store API por cada `steamAppId`.
3. Detecta el arreglo de DLC disponibles del juego base.
4. Consulta cada DLC para obtener nombre, AppID, tipo, precio, fecha y URL de tienda.
5. Actualiza `dlcInfo.dlcs` con una fila por DLC.
6. Conserva datos manuales previos cuando puede empatar por `appId` o nombre.
7. Inicializa `marker` para que la ficha use iconos visuales.
8. Regenera `games-index.json` si se usa `-BuildIndexAfter`.

## Modelo de datos DLC

Cada DLC queda así:

```json
{
  "appId": 2778580,
  "title": "ELDEN RING Shadow of the Erdtree",
  "type": "dlc",
  "owned": true,
  "marker": "owned",
  "important": true,
  "status": "propio",
  "isFree": false,
  "price": "MXN$...",
  "releaseDate": "21 JUN 2024",
  "storeUrl": "https://store.steampowered.com/app/2778580",
  "source": "steam-store-api",
  "lastSyncedAt": "2026-05-11T00:00:00Z"
}
```

## Regla manual actual

La ficha visual usa principalmente:

```json
"marker": "owned"
```

Valores recomendados:

| Marker | Icono | Uso |
|---|---:|---|
| `owned` | ✅ | Lo tenemos. |
| `missing` | ⬜ | No lo tenemos o está pendiente. |
| `skip` | 🚫 | No comprar / descartar. |
| `soundtrack` | 🎵 | Banda sonora / OST. |
| `artbook` | 📘 | Artbook / libro digital. |
| `cosmetic` | 🎨 | Cosmético, skin, outfit. |
| `currency` | 💰 | Moneda, créditos, consumible. |
| `pass` | 🧩 | Season pass, expansion pass, pack. |
| `free` | 🆓 | Contenido gratuito. |

`owned` puede seguir existiendo como dato auxiliar para conteos y compatibilidad, pero la lectura visual preferida es `marker`.

Después de editar metadata, regenera el índice:

```powershell
.\scripts\15-build-games-index-with-metadata.ps1
mdbook clean
mdbook serve --open
```

## Integración en full sync

Parámetros agregados a `05-run-full-sync.ps1`:

```powershell
-SyncSteamDlc
-DlcMaxGames 50
-DlcDelayMs 2000
-ForceSteamDlc
```

Ejemplo recomendado:

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -SyncSteamDlc `
  -DlcMaxGames 50 `
  -DlcDelayMs 2000 `
  -ValidatePaths
```

## Ficha dinámica

El bloque `DLC / contenido adicional` muestra tabla con:

| Campo | Descripción |
|---|---|
| Marca | Icono visual basado en `dlcs[].marker` o inferido desde `owned`, `status`, `isFree` y nombre. |
| DLC | Nombre, link de tienda, AppID, precio y badges auxiliares. |
| Tipo | Usualmente `dlc`, aunque Steam puede reportar otros tipos. |
| Estado | Píldora legible para `pendiente_manual`, `propio`, `faltante`, `no_comprar`, etc. |

La tabla es de lectura dentro del mdBook. La fuente de verdad sigue siendo `data/games-metadata.json`.

## Notas

- El script no intenta adivinar ownership real del usuario desde Steam.
- Si el juego ya estaba marcado como `ownershipStatus = "full"`, los DLC detectados se marcan como propios automáticamente.
- Si ya existían DLC manuales con el mismo AppID o nombre compatible, se conserva `owned`, `status` y `marker`.
- El script genera `data/dlc-sync-report.json` para revisar qué encontró.
