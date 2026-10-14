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
7. Inicializa `markers` para que la ficha use uno o varios iconos visuales por DLC.
8. Regenera `games-index.json` si se usa `-BuildIndexAfter`.

## Modelo de datos DLC

Cada DLC queda así:

```json
{
  "appId": 2778580,
  "title": "ELDEN RING Shadow of the Erdtree",
  "type": "dlc",
  "owned": true,
  "markers": ["owned", "pass"],
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
"markers": ["owned", "pass"]
```

`markers` puede tener más de un valor. El primer icono debe representar el estado principal (`owned`, `missing`, `skip` o `free`) y los demás pueden representar el tipo de contenido (`pass`, `soundtrack`, `artbook`, `cosmetic`, `currency`).

El campo legado `marker` se conserva solo por compatibilidad con metadata anterior.

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

`owned` y `status` pueden seguir existiendo como datos auxiliares para conteos y compatibilidad, pero la lectura visual preferida es `markers`. La tabla no muestra checkboxes ni texto de estado por fila: solo iconos con tooltip.

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
| Iconos | Iconos visuales basados en `dlcs[].markers[]`; acepta varios por DLC. Si faltan, se infieren desde `marker`, `owned`, `status`, `isFree` y nombre. |
| DLC | Nombre, link de tienda, AppID, precio y badges auxiliares. |
| Tipo | Usualmente `dlc`, aunque Steam puede reportar otros tipos. |

La tabla es de lectura dentro del mdBook. La fuente de verdad sigue siendo `data/games-metadata.json`.

## Notas

- El script no intenta adivinar ownership real del usuario desde Steam.
- Si el juego ya estaba marcado como `ownershipStatus = "full"`, los DLC detectados se marcan como propios automáticamente.
- Si ya existían DLC manuales con el mismo AppID o nombre compatible, se conserva `markers`; si solo existe el legado `marker`, se migra a `markers`.
- El script genera `data/dlc-sync-report.json` para revisar qué encontró.
