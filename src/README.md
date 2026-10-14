# 🎮 Biblioteca Steam — High Family

> mdBook estructurado y auditado el **2026-08-17**.
> Fuente maestra: `source-Steam-High-Family.md`.
> Auditoría actual: **93 colecciones corroboradas**, `ZZZ) El Pozo` en **190** y `ZZZ) MRD` en **57**.

Este libro separa el sistema en capas claras:

| Parte | Función |
|---|---|
| **I. Fundamentos** | Reglas del sistema y cómo leer la biblioteca |
| **II. Colecciones** | Taxonomía: técnicas, sagas, géneros, experiencias, temas y YYY |
| **III. Estados personales** | Progreso, historial, favoritos y relación personal con los juegos |
| **IV. Decisión / qué jugar** | Selector por mood, backlog activo y reglas anti-parálisis |
| **V. Juegos clave** | Fichas extendidas e imágenes por juego |
| **VI. Mantenimiento** | Sugerencias futuras, templates y reglas finales |

# Ejecutar

```powershell
mdbook serve --open
```

# Build HTML

```powershell
mdbook build
```

# Imágenes

Las imágenes por juego van en:

```text
src/assets/games/<steamAppId>/steam-header.jpg
src/assets/games/<steamAppId>/steam-capsule.jpg
src/assets/games/<steamAppId>/steam-background.jpg
```
