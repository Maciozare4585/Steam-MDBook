# 🧾 Historial técnico de versiones

Esta sección agrupa las páginas técnicas de versiones para no saturar el nivel principal de `VI. Mantenimiento`.

## Regla de organización

El sidebar de mantenimiento queda dividido así:

```text
VI. Mantenimiento
  Log de cambios histórico
  Sugerencias futuras
  Regla final resumida
  Templates copiables
  Automatización
  Historial técnico de versiones
```

Las páginas `V6.x` viven debajo de **Historial técnico de versiones**.

## Uso recomendado

- Usa **Log de cambios histórico** para entender la evolución completa.
- Usa esta rama para revisar detalles técnicos de una versión concreta.
- No agregues nuevas versiones directamente al nivel principal de mantenimiento.
- Cuando una versión solo sea hotfix operativo, puede registrarse aquí sin página técnica dedicada.

---

## Entradas de V6.5.7

- [V6.5.7 Fix sidebar / SUMMARY](v6-5-7-sidebar-summary-fix.md)
- [V6.5.7 Auditoría de consistencia](v6-5-7-auditoria-consistencia.md)

## Entradas de V6.5.8

- [V6.5.8 Acciones Steam y limpieza visual](v6-5-8-steam-actions-formatting.md)

## V6.5.9 — Perfiles personales

- Se migró `05-juegos-clave` a `05-perfiles/daniel`.
- Se agregaron perfiles plantilla para Jesse y Jovan.
- Se movió la galería global de assets a `07-juegos`.

## V6.5.10 — Favoritos de Jovan

- [V6.5.10 Favoritos de Jovan](v6-5-10-favoritos-jovan.md)
- Se registró la primera capa real de favoritos de Jovan.
- Se mantuvo `Juegos clave de Jovan` como pendiente hasta tener más contexto.

## V6.5.14 — Hotfix de registry, parser y ficha dinámica

- [V6.5.14 Parser/registry/tooltips](v6-5-14-parser-registry-tooltips.md)
- Se corrige discovery de `ZZZ) El Pozo` y `ZZZ) MRD`.
- Se limpia registry contaminado y se agrega ficha dinámica única por `steamAppId`.

---

## V6.6.0 — Metadata base y ficha extendida

- [V6.6.0 Metadata base](v6-6-0-metadata-base.md)
- Se agrega `games-metadata.json` como fuente extendida de ficha.
- Se agrega estructura para DLC, checkboxes personales, perfiles y reglas de colección.
- Se prepara el modelo de datos para `steamMetadata`, `playModes`, `steamFeatures`, `playerState`, `recommendationMetadata`, `profileMetadata`, `libraryPlacement`, `platforms` y `dataQuality`.

## V6.6.1 — Parche de limpieza, CSS y enriquecimiento

- [V6.6.1 Limpieza, CSS y enriquecimiento](v6-6-1-limpieza-css-enriquecimiento.md)
- Se archivan 2 archivos huérfanos (`06-vr-16-juegos.md`, `02-yyy-party-versus-mesa-32-juegos.md`).
- CSS: estados `--empty/--missing/--loading`, barras de prioridad, zebra en tablas, print styles.
- `game-detail.js`: loading state, fallback de imagen, fetch multi-ruta.
- Nuevo script `17-enrich-steam-metadata.ps1`: enriquece metadata desde Steam Store API.
- Nueva sección `VIII. Estadísticas` con dashboard dinámico.

## V6.6.2 — Hotfix de metadata en ficha dinámica

- Se corrige el problema donde la ficha dinámica podía mostrar `—` aunque existiera metadata real en `games-metadata.json`.
- `04-generate-game-pages.ps1` pasa a mezclar `games-metadata.json` al generar `src/assets/data/games-index.json`.
- `05-run-full-sync.ps1` incorpora flujo para `-EnrichSteamMetadata`.
- `17-enrich-steam-metadata.ps1` puede regenerar el índice al terminar mediante `-BuildIndexAfter`.

## V6.6.3 — Hotfix de invocación de metadata

- Se corrige la llamada interna a `17-enrich-steam-metadata.ps1` desde `05-run-full-sync.ps1`.
- Se evita el error donde PowerShell intentaba convertir `-DelayMs` a `System.Int32` por pasar mal los argumentos.
- El flujo recomendado queda con parámetros explícitos:

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -EnrichSteamMetadata -MetadataMaxGames 100 -MetadataDelayMs 2000
```

## V6.6.4 — Hotfix de rutas y propiedades dinámicas

- Se corrige la ruta rota hacia `17-enrich-steam-metadata.ps1` usando `Join-Path`.
- Se corrige el caso donde `lastEnrichedAt` no existía todavía en `dataQuality`.
- El script ahora crea propiedades faltantes antes de asignarlas.
- Se estabiliza el flujo completo de metadata desde `05-run-full-sync.ps1`.

## V6.6.5 — DLC manual y juegos nuevos

- Se agregan Blue Protocol: Star Resonance, Desktop Mate, Supermarket Together y Transformice al registry, metadata y colecciones existentes.
- Se registra propiedad manual de DLC para juegos clave y sagas específicas.
- Se amplía `dlcInfo` con `ownershipStatus`, `ownershipSummary`, `missingNotes`, `manualSource` y `lastManualUpdateAt`.
- La ficha dinámica ahora muestra estado de DLC manual sin depender de conteos exactos de Steam.

## V6.6.6 — Catálogo DLC desde Steam

- [V6.6.6 Catálogo DLC](v6-6-6-dlc-catalog-iconos.md)
- Se agrega `scripts/18-sync-steam-dlc.ps1` para consultar el catálogo de DLC disponibles por juego desde Steam Store.
- El script lee `data/games-metadata.json`, consulta cada `steamAppId` y genera filas dentro de `dlcInfo.dlcs`.
- Se agregan parámetros al full sync:
  - `-SyncSteamDlc`
  - `-DlcMaxGames`
  - `-DlcDelayMs`
  - `-ForceSteamDlc`
- La ficha dinámica muestra una tabla de DLC por juego con AppID, nombre, tipo, precio, gratuidad, estado y datos manuales.
- El flujo conserva datos manuales existentes cuando puede empatar por `appId` o por nombre.

## V6.6.7 — Sistema visual de iconos para DLC

- Se reemplaza la lectura visual tipo checkbox por un sistema de iconos basado en `dlcInfo.dlcs[].marker`.
- Valores principales de `marker`:

| Marker | Icono | Significado |
|---|---:|---|
| `owned` | ✅ | Lo tenemos. |
| `missing` | ⬜ | No lo tenemos / pendiente. |
| `skip` | 🚫 | No comprar. |
| `soundtrack` | 🎵 | Banda sonora / OST. |
| `artbook` | 📘 | Artbook / libro digital. |
| `cosmetic` | 🎨 | Cosmético / skin / outfit. |
| `currency` | 💰 | Moneda, créditos o consumible. |
| `pass` | 🧩 | Season pass, expansion pass o pack. |
| `free` | 🆓 | Contenido gratuito. |

- `game-detail.js` ahora infiere `marker` cuando no existe, usando `owned`, `status`, `isFree` y palabras clave del nombre del DLC.
- `18-sync-steam-dlc.ps1` conserva `marker` manual si ya existía y puede inicializarlo automáticamente.
- `theme/custom.css` agrega estilos para la leyenda visual y las píldoras de DLC.

## V6.6.8 — README operativo y CSS documentado

- Se actualiza `README.md` para reflejar el flujo nuevo de DLC con `marker` en vez de checkboxes.
- Se documentan comandos de metadata, DLC, full sync, reparación, tooltips, assets y diagnóstico.
- Se corrige el comando resumido del final para evitar un backtick sobrante.
- Se documenta `theme/custom.css` para que sea más fácil modificar colores del proyecto.
- Se agrega una capa de variables CSS semánticas para centralizar acentos, superficies, bordes, prioridades, perfiles y DLC markers.
- Se reduce la dependencia de colores hardcodeados como `#4f8cff` y `rgba(125, 170, 255, ...)`.


## V6.6.9 — Estabilización UI, enlaces y documentación

- [V6.6.9 Estabilización UI/scripts](v6-6-9-estabilizacion-ui-scripts.md)
- Se corrige el fallback roto de imagen en `game-detail.js` que podía dejar basura visual por un handler `onerror` mal escapado.
- Se consolida la tabla DLC con iconos y estado legible, evitando texto crudo como `pendiente_manual` en la vista.
- Se corrigen enlaces de `fichas-extendidas.md` y `galeria-assets-generada.md` para abrir directamente `detalle.html?id=<steamAppId>`.
- Se corrigen los scripts generadores `10` y `13` para que no vuelvan a generar enlaces hacia páginas intermedias por letra.
- Se agregan bloques de documentación a scripts PowerShell y headers JSDoc a scripts JavaScript del tema.

---

## Estado técnico actual recomendado

Para una corrida general razonable:

```powershell
.\scripts\05-run-full-sync.ps1 `
  -DiscoverFromMarkdown `
  -AllowFuzzy `
  -ValidatePaths `
  -EnrichSteamMetadata `
  -MetadataMaxGames 100 `
  -MetadataDelayMs 2000 `
  -SyncSteamDlc `
  -DlcMaxGames 100 `
  -DlcDelayMs 2000
```

Después:

```powershell
mdbook clean
mdbook build
mdbook serve --open
```

Y en navegador:

```text
Ctrl + F5
```
