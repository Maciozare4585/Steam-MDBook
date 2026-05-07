# 🩹 V6.5.1 — Fix tooltips y enlaces de metadatos

Esta versión corrige dos problemas de la V6.5.

## Problemas corregidos

| Problema | Causa | Solución |
|---|---|---|
| Tooltip atrapado dentro de tablas | mdBook envuelve tablas en `.table-wrapper` con `overflow` | CSS específico con `:has(.game-hover)` para permitir overflow visible |
| Links `07-juegos/<appid>.html` dan 404 | mdBook solo renderiza páginas listadas en `SUMMARY.md`; las fichas individuales no estaban en el índice | Las colecciones ahora enlazan a `07-juegos/index.html#game-meta-<appid>` |
| No queremos cientos de juegos en sidebar | Meter todos los juegos al `SUMMARY.md` ensucia la navegación | Se usa una sola página renderizada de metadatos con anclas por juego |

## Regla nueva

```text
Colección → 07-juegos/index.html#game-meta-<steamAppId>
```

Las fichas individuales `src/07-juegos/<steamAppId>.md` se conservan como archivos auxiliares/debug, pero la navegación pública usa el índice renderizado.

## Comandos útiles

```powershell
.\scripts\04-generate-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

Si el navegador conserva links viejos:

```text
Ctrl + F5
```
