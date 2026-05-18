# V6.6.9 — Estabilización UI, enlaces y documentación de scripts

## Objetivo

Corregir regresiones visuales y de navegación detectadas después de integrar metadata extendida, DLC e iconos.

## Correcciones aplicadas

### Ficha dinámica de juego

- Se corrigió el fallback roto de imagen que podía mostrar texto sucio por un handler `onerror` mal escapado dentro de `innerHTML`.

- El fallback ya no usa un handler largo dentro del atributo `onerror`.
- Ahora `theme/game-detail.js` expone una función controlada:

```js
window.__steamDetailImgFallback(img)
```

- La imagen hero usa:

```html
onerror="__steamDetailImgFallback(this)"
```

Esto evita romper el HTML por comillas escapadas dentro de `innerHTML`.

### DLC con iconos

- La tabla DLC queda consolidada como sistema de iconos, no checkboxes.
- La columna `Iconos` usa `dlcInfo.dlcs[].markers[]` y puede mostrar más de un icono por DLC.
- La columna `Estado` ya no muestra texto crudo como `pendiente_manual`; ahora usa píldoras legibles:
  - `🕐 Pendiente`
  - `✅ Propio`
  - `⬜ Faltante`
  - `🚫 No comprar`
  - `🆓 Gratis`

### Enlaces de metadata

- Las fichas extendidas de Daniel ahora abren directamente:

```text
../../07-juegos/detalle.html?id=<steamAppId>
```

- La galería global de assets ahora abre directamente:

```text
detalle.html?id=<steamAppId>
```

- Se corrigieron los scripts generadores para evitar que vuelvan a crear enlaces hacia páginas intermedias por letra.

### Scripts documentados

- Se agregaron bloques de ayuda compatibles con `Get-Help` en scripts PowerShell que no tenían documentación.
- También se agregaron headers JSDoc en los scripts JavaScript del tema.

## Archivos tocados

| Archivo | Cambio |
|---|---|
| `theme/game-detail.js` | Fallback seguro, documentación JSDoc, estado DLC con iconos múltiples. |
| `theme/game-tooltips.js` | Header JSDoc. |
| `theme/sidebar-persist.js` | Header JSDoc. |
| `theme/custom.css` | Estilos para fallback de imagen y estado DLC. |
| `src/05-perfiles/daniel/fichas-extendidas.md` | Enlaces directos a `detalle.html?id=`. |
| `src/07-juegos/galeria-assets-generada.md` | Enlaces directos a `detalle.html?id=`. |
| `scripts/10-generate-assets-gallery.ps1` | Genera enlaces directos a detalle dinámico. |
| `scripts/13-generate-extended-key-sheets.ps1` | Genera enlaces directos a detalle dinámico. |
| `scripts/*.ps1` | Documentación operativa inicial. |

## Validación recomendada

```powershell
.\scripts\15-build-games-index-with-metadata.ps1
.\scripts\10-generate-assets-gallery.ps1
.\scripts\13-generate-extended-key-sheets.ps1
.\scripts\07-generate-collection-tooltips.ps1

mdbook clean
mdbook build
mdbook serve --open
```

Después usa:

```text
Ctrl + F5
```
