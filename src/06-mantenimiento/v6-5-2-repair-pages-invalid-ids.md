# 🩹 V6.5.2 — Repair de páginas auxiliares e IDs inválidos

Esta versión corrige dos fallas operativas detectadas al correr `mdbook serve`.

## Problemas corregidos

| Problema | Causa | Solución |
|---|---|---|
| `Chapter file not found, 07-juegos/review-needed.md` | El `SUMMARY.md` referenciaba páginas auxiliares que podían faltar en una extracción/overlay | Nuevo script `09-repair-mdbook-pages.ps1` regenera `review-needed.md`, `retry-needed.md` e `ignored.md` |
| `WARN: / 0: Response status code does not indicate success: 400` | Alguna entrada local tenía `steamAppId = 0` o inválido | `02-download-steam-images.ps1` ya no consulta Steam con `appid <= 0`; lo manda a review |
| Build frágil | Las páginas auxiliares dependían de que ya existieran físicamente | `05-run-full-sync.ps1` ejecuta repair al inicio y al final |

## Comandos recomendados

```powershell
.\scripts\09-repair-mdbook-pages.ps1
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown
mdbook serve --open
```

Si solo quieres arreglar el error de `review-needed.md`:

```powershell
.\scripts\09-repair-mdbook-pages.ps1
mdbook serve --open
```
