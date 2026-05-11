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


## V6.6.1 — Parche de limpieza, CSS y enriquecimiento

- [V6.6.1 Limpieza, CSS y enriquecimiento](v6-6-1-limpieza-css-enriquecimiento.md)
- Se archivan 2 archivos huérfanos (`06-vr-16-juegos.md`, `02-yyy-party-versus-mesa-32-juegos.md`).
- CSS: estados `--empty/--missing/--loading`, barras de prioridad, zebra en tablas, print styles.
- `game-detail.js`: loading state, fallback de imagen, fetch multi-ruta.
- Nuevo script `17-enrich-steam-metadata.ps1`: enriquece metadata desde Steam Store API.
- Nueva sección `VIII. Estadísticas` con dashboard dinámico.

## V6.6.0 — Metadata base y ficha extendida

- [V6.6.0 Metadata base](v6-6-0-metadata-base.md)
- Se agrega `games-metadata.json` como fuente extendida de ficha.
- Se agrega estructura para DLC, checkboxes personales, perfiles y reglas de colección.

## V6.6.5 · DLC y juegos nuevos

- Se agregan Blue Protocol: Star Resonance, Desktop Mate, Supermarket Together y Transformice al registry, metadata y colecciones existentes.
- Se registra propiedad manual de DLC para juegos clave y sagas específicas.
- Se amplía `dlcInfo` con `ownershipStatus`, `ownershipSummary`, `missingNotes`, `manualSource` y `lastManualUpdateAt`.
- La ficha dinámica ahora muestra estado de DLC manual sin depender de conteos exactos de Steam.
