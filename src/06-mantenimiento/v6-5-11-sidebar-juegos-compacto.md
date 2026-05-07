# V6.5.11 — Sidebar de juegos compacto

## Objetivo

Reducir el ruido visual provocado por la sección `VII. Juegos / Metadatos` cuando el sidebar muestra demasiadas entradas de juegos.

## Cambios

- `VII. Juegos / Metadatos` deja de comportarse como una lista gigante de juegos individuales.
- `07-juegos/index.md` queda como índice compacto.
- Los juegos se dividen en páginas alfabéticas bajo `07-juegos/por-letra/`.
- Se conservan anclas `game-meta-APP_ID` para no romper enlaces antiguos.
- Se actualiza el generador de páginas para no volver a meter encabezados masivos en la vista global.
- Se agrega script de saneamiento para limpiar el bloque de juegos del `SUMMARY.md` si algún proceso vuelve a llenarlo.

## Resultado esperado

Al abrir `VII. Juegos / Metadatos`, el sidebar muestra páginas útiles por letra, no cientos de juegos sueltos.

## Regla nueva

Los juegos individuales pueden existir como datos o fichas auxiliares, pero no deben listarse de forma exhaustiva en `SUMMARY.md`.
