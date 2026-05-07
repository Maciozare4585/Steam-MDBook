# 🩹 V6.4.1 — Limpieza fina de registry

Esta versión parchea la V6.4 sin cambiar la arquitectura base.

## Cambios principales

| Área | Cambio |
|---|---|
| Filtros | `DmC Devil May Cry` e `I’m not a Monster` ya no se confunden con numerales romanos |
| Review | Se eliminó basura de Markdown como `Juego`, `Juego 1`, `Galería automática de assets` |
| Retry | Los errores `429 Too Many Requests` se separan en `steam-games-retry-needed.json` |
| Registry | Se limpió el título accidental `️ XCOM 2` a `XCOM 2` |
| Overrides | Se agregó `dmc-devil-may-cry = 220440` |
| Scripts | `01-sync-steam-ids.ps1` y `02-download-steam-images.ps1` manejan rate limit mejor |

## Estado actual

| Archivo | Conteo |
|---|---:|
| `steam-games-registry.json` | 665 |
| `steam-image-targets.json` | 666 |
| `steam-games-review-needed.json` | 70 |
| `steam-games-retry-needed.json` | 0 |
| `steam-games-ignored.json` | 3 |

## Flujo recomendado

```powershell
Get-ChildItem .\scripts\*.ps1 | Unblock-File
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown
```

Con SteamGridDB:

```powershell
$env:STEAMGRIDDB_API_KEY = "TU_API_KEY"
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -UseSteamGridDb
```

## Revisión humana

Primero revisa:

```text
data/steam-games-review-needed.json
```

Después, si hubo rate limit:

```text
data/steam-games-retry-needed.json
```

Los `retry-needed` no deberían corregirse manualmente salvo que se repitan muchas veces.
