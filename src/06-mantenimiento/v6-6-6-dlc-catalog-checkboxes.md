# V6.6.6 — Catálogo DLC con checkboxes manuales

## Objetivo

Agregar una capa automática para detectar los DLC disponibles de cada juego desde Steam y mostrarlos en la ficha dinámica como una tabla editable desde metadata.

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
6. Deja `owned` como checkbox manual.
7. Regenera `games-index.json` si se usa `-BuildIndexAfter`.

## Modelo de datos DLC

Cada DLC queda así:

```json
{
  "appId": 2778580,
  "title": "ELDEN RING Shadow of the Erdtree",
  "type": "dlc",
  "owned": false,
  "important": null,
  "status": "pendiente_manual",
  "isFree": false,
  "price": "MXN$...",
  "releaseDate": "21 JUN 2024",
  "storeUrl": "https://store.steampowered.com/app/2778580",
  "source": "steam-store-api",
  "lastSyncedAt": "2026-05-11T00:00:00Z"
}
```

## Regla manual

El campo importante es:

```json
"owned": false
```

Cuando se confirme que el DLC sí está en la biblioteca familiar, se cambia a:

```json
"owned": true
```

Después se regenera el índice:

```powershell
.\scripts\15-build-games-index-with-metadata.ps1
mdbook clean
mdbook serve --open
```

## Integración en full sync

Se agregaron parámetros a `05-run-full-sync.ps1`:

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

El bloque `DLC / contenido adicional` ahora muestra tabla con:

| Campo | Descripción |
|---|---|
| Lo tenemos | Checkbox visual basado en `dlcs[].owned`. |
| DLC | Nombre, link de tienda y AppID. |
| Tipo | Usualmente `dlc`. |
| Importa | Checkbox manual para marcar DLC relevantes. |
| Estado | Estado textual, por ejemplo `pendiente_manual`, `propio`, `faltante`. |

Los checkboxes son de lectura dentro del mdBook. La fuente de verdad sigue siendo `data/games-metadata.json`.

## Notas

- El script no intenta adivinar ownership real del usuario desde Steam.
- Si el juego ya estaba marcado como `ownershipStatus = "full"`, los DLC detectados se marcan como propios automáticamente.
- Si ya existían DLC manuales con el mismo AppID o nombre compatible, el valor `owned` se conserva.
- El script genera `data/dlc-sync-report.json` para revisar qué encontró.
