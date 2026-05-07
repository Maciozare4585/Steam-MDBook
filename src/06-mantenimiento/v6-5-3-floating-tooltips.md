# 🩹 V6.5.3 — Tooltips flotantes

Esta versión corrige el recorte de previews dentro de tablas.

## Problema

Aunque el tooltip tuviera `z-index` alto, seguía viviendo dentro de la estructura de la tabla.
Cuando mdBook envuelve tablas en contenedores con scroll/overflow, el preview se recorta.

## Solución

Ahora el tooltip visual se renderiza con JavaScript como elemento flotante en `document.body`.

```text
tabla / celda / link
        ↓ hover
document.body / .game-floating-preview
```

Así el preview ya no depende del alto de la fila ni del overflow de la tabla.

## Archivos nuevos/modificados

| Archivo | Cambio |
|---|---|
| `theme/game-tooltips.js` | Crea tooltip flotante fuera de la tabla |
| `theme/custom.css` | Estilos de `.game-floating-preview` |
| `book.toml` | Agrega `theme/game-tooltips.js` en `additional-js` |
| `scripts/07-generate-collection-tooltips.ps1` | Agrega `data-preview-src` y `data-game-title` |

## Qué correr

```powershell
.\scripts\07-generate-collection-tooltips.ps1
mdbook serve --open
```

Si el navegador conserva el JS anterior:

```text
Ctrl + F5
```
