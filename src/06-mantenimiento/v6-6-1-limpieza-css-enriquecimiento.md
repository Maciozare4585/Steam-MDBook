# V6.6.1 — Parche de limpieza, CSS y enriquecimiento

## Objetivo

Corregir bugs menores, mejorar la experiencia visual de la ficha dinámica y agregar herramientas de enriquecimiento de metadata.

## Bugs corregidos

### Archivos huérfanos archivados

Existían dos archivos que no figuraban en `SUMMARY.md` y eran versiones antiguas reemplazadas:

- `src/02-colecciones/experiencias/06-vr-16-juegos.md` → archivado en `src/_orphaned/`
- `src/02-colecciones/sociales/02-yyy-party-versus-mesa-32-juegos.md` → archivado en `src/_orphaned/`

En ese corte, los archivos activos eran `06-vr-17-juegos.md` y `02-yyy-party-versus-mesa-33-juegos.md`. En versiones posteriores, VR fue actualizado a `06-vr-21-juegos.md`.

### Fallback de imagen en ficha dinámica

`game-detail.js` ahora maneja el caso en que no existe `steam-header.jpg` para un juego. Antes mostraba imagen rota; ahora muestra un ícono `🎮` como placeholder.

### Carga adaptativa de `games-index.json`

`game-detail.js` intentaba una única ruta relativa (`../assets/data/games-index.json`). Ahora prueba tres rutas posibles, lo que soluciona errores cuando la ficha se abre desde páginas a diferente profundidad de directorio.

## Mejoras de CSS (`theme/custom.css`)

### Estados faltantes de la ficha dinámica

Se agregan estilos para:

- `.game-detail--empty` y `.game-detail--missing`: centrados con ícono descriptivo.
- `.game-detail--loading`: spinner animado mientras se carga `games-index.json`.

### Nuevos componentes visuales

- `.state-count`: badge numérico para mostrar conteo junto a estados.
- `.priority-badge` con variantes `--alta`, `--media`, `--baja`: para el backlog activo.
- Encabezado de panel (`.game-detail__panel h3`) con separador visual.
- Filas zebra suaves en tablas de detalle.
- Sticky header en `.verdict-table` para colecciones largas.

### Mejoras responsive

- En pantallas ≤ 600px, los paneles de detalle pasan a columna única explícitamente.
- Los cards compactos reducen padding y relación de aspecto de imagen en móvil.

### Estilos de impresión

Nuevo bloque `@media print`:
- Oculta sidebar, navegación y botones de Steam.
- El contenido ocupa el 100% del ancho.

## Nuevo script

### `17-enrich-steam-metadata.ps1`

Consulta la Steam Store API (`/api/appdetails`) para cada juego con `steamMetadata` vacío y escribe de vuelta en `games-metadata.json`:

- Géneros, categorías, descripción corta, fecha de lanzamiento.
- Developers y publishers.
- `playModes`: singlePlayer, localMultiplayer, onlineMultiplayer, localCoop, onlineCoop.
- `steamFeatures`: achievements, cloudSaves, fullControllerSupport, remotePlayTogether, workshop, tradingCards, vrSupported.

Parámetros:
- `-MaxGames N`: procesa solo N juegos (útil para runs parciales).
- `-DelayMs N`: delay entre llamadas (default 1500ms).
- `-Force`: re-enriquece aunque ya tenga metadata.
- `-DryRun`: imprime qué haría sin escribir nada.

> Ejecutar después: `.\scripts\15-build-games-index-with-metadata.ps1` para reflejar los cambios en el mdBook.

## Nueva sección del libro

### `VIII. Estadísticas` (`src/08-estadisticas/index.md`)

Página dinámica que carga `games-index.json` y muestra:

- Contadores globales: total de juegos, historias terminadas, favoritos, 100% completados, abandonados, y porcentaje con metadata enriquecida.
- Distribución de estados personales con barras proporcionales.
- Modos de juego confirmados (single-player, multiplayer online, co-op, VR).
- Top 8 géneros más frecuentes (requiere metadata enriquecida).

No requiere pasos adicionales de build: la página se genera dinámicamente en el navegador con los datos ya existentes en `games-index.json`.
