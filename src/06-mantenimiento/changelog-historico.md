# 📜 Log de cambios histórico

> Resumen de evolución del documento y mdBook durante esta sesión.
> No es una bitácora de cada captura; es una línea histórica práctica para saber **qué cambió**, **por qué cambió** y **qué versión conviene usar como base**.

---

# Línea estable actual

| Rama | Estado |
|---|---|
| Documento maestro Markdown | Base práctica: `biblioteca_steam_documento_maestro_v3_3_4.md` |
| mdBook | Base estable actual: **V6.5.13** |
| Identidad técnica | `steamAppId` es la identidad canónica |
| Criterio rector | Limpieza > exhaustividad |

---

# 1. Etapa Markdown inicial

## V1 — Documento maestro base

**Objetivo:** convertir la revisión de capturas de Steam en un documento maestro legible.

Cambios principales:

- Se definió la lógica base de organización:
  - franquicia / universo
  - género
  - experiencia / contexto
  - estados personales
- Se separaron colecciones normales de colecciones meta.
- Se documentó que `ZZZ) El Pozo` y `ZZZ) MRD` son cuarentena/staging, no categorías finales.
- Se dejó claro que los duplicados solo valen si son **duplicados nutritivos**.

---

## V2 — Más diseño y sistema visual

**Objetivo:** hacer el Markdown menos austero y más usable visualmente.

Cambios principales:

- Se agregó un sistema de iconos.
- Se mejoraron títulos, secciones y jerarquía visual.
- Se empezó a distinguir mejor entre:
  - explicación del sistema
  - colecciones reales
  - estados personales
  - recomendaciones
- Se incorporó la idea de agregar más información independiente de cada juego.

---

## V3 — Estado actual, no bitácora

**Objetivo:** dejar de presentar el documento como historial de cambios y pasar a mostrar el **estado actual** de la biblioteca.

Cambios principales:

- Se reforzó la regla: `destino sugerido` no significa mover automáticamente.
- Se aclaró que un juego puede estar en colección de estado y en colección temática al mismo tiempo.
- Se dejó `Shooter` como colección madre sin partir prematuramente.
- Se evitó presentar tablas simplistas tipo:
  - `Final Fantasy VII | Nombre correcto`
  - `Dying Light | Solo juegos principales`
  - `Bandas sonoras | OST separado`
- Se consolidó la diferencia entre taxonomía y colecciones meta/estado:
  - `TODO LO TOCADO`
  - `ABANDONADO`
  - `REPLAY`
  - `PA PLATINAR`
  - `SIN TERMINAR`
  - `TERMINADOS`
  - `POSTGAME / EXTRAS`

---

## V3.1 — Corrección de repetición

**Objetivo:** limpiar repetición visual.

Cambios principales:

- La nota de `Starbound se queda como excepción aceptada` dejó de repetirse por cada fila.
- Se movió a una nota única al inicio de la sección correspondiente.

---

## V3.2 — Sistema visual completo

**Objetivo:** corregir iconos usados pero no definidos.

Cambios principales:

- Se agregó `🃏` al sistema visual.
- Se cerró la inconsistencia de `🃏 Cartas / 🌐 Online`.

---

## V3.3 / V3.3.2 / V3.3.4 — Documento maestro práctico

**Objetivo:** consolidar el documento maestro como referencia práctica.

Cambios principales:

- Se completaron listas exactas faltantes en `8.1` para:
  - Age of Empires
  - Assassin’s Creed
  - Batman
  - Battlefield
  - BioShock
  - Borderlands
  - LEGO
- Se corrigió numeración interna de secciones.
- Se validó la estructura final.
- Se decidió usar `biblioteca_steam_documento_maestro_v3_3_4.md` como versión base/canónica práctica.
- La versión PDF-safe quedó como alternativa de exportación.

---

# 2. Nuevas colecciones y estado

## `2.5) POSTGAME / EXTRAS`

**Objetivo:** separar juegos ya pasados/cerrados, pero con contenido importante pendiente.

Criterio:

- historia/base ya cerrada
- queda DLC, postgame, finales, opcionales, figuras, jefes, coleccionables o extras relevantes

Ejemplos:

- Hollow Knight
- Elden Ring
- DAVE THE DIVER
- The Witcher 3
- Terraria
- Stardew Valley

---

## Limpieza de `Sin categoría`

| Juego / app | Destino |
|---|---|
| Escape the Backrooms | `YYY) Historia / Puzzle` |
| Gang Beasts | `YYY) Party / Versus / Mesa` |
| Godot Engine | `ZZZ) Demos y otros` |
| Guns of Icarus Alliance | `YYY) PvE / Acción` + `Internet Persistente` |
| Lethal Company | `YYY) PvE / Acción` |
| Mage Arena | `YYY) Party / Versus / Mesa` + `Internet Persistente` |
| Plunder Panic | `YYY) Party / Versus / Mesa` |
| Rayman: Raving Rabbids | `YYY) Party / Versus / Mesa` |
| Rogue Heroes: Ruins of Tasos | `YYY) PvE / Acción` |
| Rubber Bandits | `YYY) Party / Versus / Mesa` |
| Sanctum 2 | `YYY) PvE / Acción` |
| Spacelines From The Far Out | `YYY) Party / Versus / Mesa` |
| SteamVR | `ZZZ) Demos y otros` |
| Wallpaper Engine | `ZZZ) Demos y otros` |

---

# 3. Etapa mdBook

## V4 / V5 — Migración conceptual a mdBook

**Objetivo:** pasar del Markdown único a un libro navegable.

Cambios principales:

- Se separó contenido por ramas:
  - fundamentos
  - colecciones
  - estados
  - decisión / qué jugar
  - juegos clave
  - mantenimiento
- Se agregaron secciones para:
  - selector rápido por mood
  - backlog activo recomendado
  - fichas extendidas
  - reglas de decisión
  - templates
- Se inició la idea de páginas independientes por juego.

---

## V6 — Assets Steam iniciales

**Objetivo:** conectar mdBook con imágenes oficiales de Steam.

Cambios principales:

- Se agregó script para descargar assets de Steam.
- Se empezó a descargar:
  - `header`
  - `capsule`
  - `background`
- Se generaron reportes:
  - `steam-assets-report.csv`
  - `steam-assets-report.json`

Problemas detectados:

- Se usaban rutas por `slug`.
- Algunos matches de Steam Search eran falsos positivos.
- El script era demasiado permisivo.

---

## V6.1 / V6.2 — Correcciones del script de assets

**Objetivo:** corregir errores PowerShell y dependencia de endpoints.

Cambios principales:

- Se corrigió interpolación inválida (`$appid:` → `${appid}:`).
- Se dejó de depender de `ISteamApps/GetAppList`.
- Se usó `storesearch` para resolver IDs faltantes.
- Se mantuvo `appdetails` para metadata e imágenes.

---

## V6.3 — Cambio B: registry por Steam App ID

**Objetivo:** hacer que `steamAppId` sea la identidad canónica.

Cambios principales:

- Se creó `data/steam-games-registry.json`.
- Las imágenes empezaron a guardarse por ID:

```text
src/assets/games/<steamAppId>/steam-header.jpg
src/assets/games/<steamAppId>/steam-capsule.jpg
src/assets/games/<steamAppId>/steam-background.jpg
```

- Se agregó soporte opcional para SteamGridDB:
  - hero
  - grid
  - logo
  - icon
- Se generaron páginas genéricas en `src/07-juegos`.

Problemas detectados:

- `DiscoverFromMarkdown` detectaba encabezados como juegos.
- `storesearch-first` y `storesearch-contains` contaminaban el registry.
- El pipeline volvía a buscar/descargar datos existentes.

---

## V6.4 — Registry limpio y scripts separados

**Objetivo:** separar responsabilidades y evitar contaminación.

Cambios principales:

- Se separó el pipeline:
  - `01-sync-steam-ids.ps1`
  - `02-download-steam-images.ps1`
  - `03-sync-steamgriddb-assets.ps1`
  - `04-generate-game-pages.ps1`
  - `05-run-full-sync.ps1`
- Se creó `steam-games-review-needed.json`.
- Se creó `steam-games-ignored.json`.
- Los matches dudosos dejaron de entrar automáticamente al registry.
- Se corrigieron falsos positivos:
  - FATE
  - Lost Ark
  - Prototype 2
  - Shadow of the Tomb Raider
  - BioShock Infinite
  - Assassin’s Creed
  - Assassin’s Creed II
  - Age of Empires II (2013)

---

## V6.4.1 — Limpieza fina

**Objetivo:** corregir filtros y separar errores temporales.

Cambios principales:

- `DmC Devil May Cry` dejó de confundirse con encabezado/numeral romano.
- `I’m not a Monster` dejó de confundirse con encabezado/numeral romano.
- Se agregó override limpio para `DmC Devil May Cry`.
- Se corrigió `️ XCOM 2` → `XCOM 2`.
- Los errores `429 Too Many Requests` se separaron en `steam-games-retry-needed.json`.

---

## V6.4.2 — IDs agregados y cache

**Objetivo:** completar IDs faltantes y evitar reprocesar todo.

Cambios principales:

- Se agregaron IDs faltantes a registry/overrides.
- Se redujo `review-needed`.
- Se reforzó la política de cache:
  - reutilizar IDs existentes
  - no volver a buscar si ya hay `steamAppId`
  - no descargar imágenes ya existentes
- Se propusieron banderas:
  - `-OnlyMissing`
  - `-RefreshMetadata`
  - `-ForceSearch`
  - `-SkipExistingAssets`

Resultado:

- El full sync dejó de tardar más de una hora y pasó a correr en segundos cuando no había pendientes.

---

# 4. Etapa UI/UX del mdBook

## V6.5 — Navegación, rutas relativas y previews

**Objetivo:** mejorar navegación, sidebar y visuales.

Cambios principales:

- `book.toml` quedó con:

```toml
[output.html.fold]
enable = true
level = 0
```

- `SUMMARY.md` dejó de usar headers tipo `# I. Fundamentos`.
- Las secciones pasaron a ser capítulos padre reales.
- Se quitaron juegos clave individuales del sidebar.
- Se corrigieron fichas clave para usar imágenes por Steam App ID.
- Se agregaron tooltips visuales en tablas de colecciones.
- Se agregaron helpers:
  - `Get-ProjectRoot`
  - `ConvertTo-ProjectRelativePath`
  - `Get-MdBookRelativeAssetPath`
- Se agregó `99-validate-project-paths.ps1`.

---

## V6.5.1 — Fix tooltips y enlaces de metadatos

**Objetivo:** corregir links 404 sin llenar el sidebar.

Problema:

- mdBook no renderiza páginas que no están en `SUMMARY.md`.
- Los links a `07-juegos/<appid>.html` daban 404.

Solución:

- Las colecciones enlazan a:

```text
07-juegos/index.html#game-meta-<steamAppId>
```

- `src/07-juegos/index.md` se volvió la página genérica real de metadatos.
- Los archivos `src/07-juegos/<appid>.md` quedaron como auxiliares/debug.

---

## V6.5.2 — Repair de páginas auxiliares e IDs inválidos

**Objetivo:** evitar que `mdbook serve` truene por páginas auxiliares faltantes o IDs inválidos.

Cambios principales:

- Se agregó `09-repair-mdbook-pages.ps1`.
- Se regeneran automáticamente:
  - `review-needed.md`
  - `retry-needed.md`
  - `ignored.md`
- `02-download-steam-images.ps1` dejó de consultar Steam con `appid = 0`.
- `05-run-full-sync.ps1` corre repair al inicio y al final.

---

## V6.5.3 — Tooltips flotantes

**Objetivo:** evitar que la tabla se coma los previews.

Problema:

- El tooltip vivía dentro de la tabla.
- `table-wrapper`/overflow lo recortaba.

Solución:

- Se agregó `theme/game-tooltips.js`.
- El preview se renderiza como elemento flotante en `document.body`.
- Se agregó `additional-js` en `book.toml`.
- Se añadieron `data-preview-src` y `data-game-title`.

Resultado:

- Tooltip visual funcionando correctamente fuera de la tabla.

---

## V6.5.4 — Galería automática de assets

**Objetivo:** reemplazar el placeholder viejo de galería.

Problema:

- `galeria-assets-generada.md` seguía mostrando instrucciones del script anterior.

Solución:

- Se agregó `10-generate-assets-gallery.ps1`.
- La galería lee `steam-games-registry.json`.
- Genera cards visuales para juegos con metadata.
- Cada card enlaza a:

```text
../07-juegos/index.html#game-meta-<steamAppId>
```

---

## V6.5.5 — Log de cambios histórico

**Objetivo:** dejar documentada la evolución de versiones.

Cambios principales:

- Se agregó esta página:
  - `src/06-mantenimiento/changelog-historico.md`
- Se agregó al sidebar dentro de:
  - `VI. Mantenimiento`

---

## V6.5.6 — Fix script de galería automática

**Objetivo:** corregir que la galería automática de assets no pudiera regenerarse porque faltaba el script correspondiente.

### Problema

La versión anterior incluía la página de galería automática, pero al ejecutar:

```powershell
.\scripts\10-generate-assets-gallery.ps1
```

PowerShell marcaba que el script no existía.

Esto pasó porque la versión con changelog fue generada desde una rama que no traía todavía el script de galería.

### Cambios principales

- Se agregó nuevamente:

```text
scripts/10-generate-assets-gallery.ps1
```

- Se regeneró:

```text
src/05-juegos-clave/galeria-assets-generada.md
```

- La galería volvió a leer desde:

```text
data/steam-games-registry.json
```

- Cada card de la galería enlaza a:

```text
../07-juegos/index.html#game-meta-<steamAppId>
```

### Comando relacionado

```powershell
.\scripts\10-generate-assets-gallery.ps1
```

### Resultado

La galería automática dejó de ser una página placeholder y volvió a funcionar como página visual global de assets.

---

## V6.5.7 — Fix sidebar / SUMMARY

**Objetivo:** corregir y ordenar la jerarquía del sidebar en `src/SUMMARY.md`.

### Problema

Los templates quedaron accidentalmente anidados debajo de una página técnica de versión:

```text
V6.5.3 Tooltips flotantes
  Template de mood nuevo
  Template de selector anti-parálisis
  Template de selector por tiempo
```

Esto pasaba por un error de indentación en `SUMMARY.md`.

### Cambios principales

- Se corrigió la jerarquía de `VI. Mantenimiento`.
- Se agregó `theme/sidebar-persist.js` para conservar el ancho manual del sidebar.
- Se registró el script en `book.toml` junto a `theme/game-tooltips.js`.
- Los templates quedaron bajo:

```text
Templates copiables
```

- Las páginas técnicas `V6.x` quedaron agrupadas bajo:

```text
Historial técnico de versiones
```

- Los documentos de automatización quedaron agrupados bajo:

```text
Automatización
```

### Nueva estructura

```text
VI. Mantenimiento
  Log de cambios histórico
  Sugerencias futuras
  Regla final resumida
  Templates copiables
    Template de mood nuevo
    Template de selector anti-parálisis
    Template de selector por tiempo
    ...
  Automatización
    Automatización de imágenes Steam
    Automatización imágenes: Registry + SGDB
  Historial técnico de versiones
    V6.4 Registry limpio
    V6.4.1 Limpieza fina
    V6.4.2 IDs agregados/cache
    V6.5 Navegación y previews
    V6.5.1 Fix tooltips y enlaces
    V6.5.2 Repair páginas auxiliares
    V6.5.3 Tooltips flotantes
    V6.5.4 Galería automática
    V6.5.5 Changelog histórico
    V6.5.6 Fix script de galería
    V6.5.7 Fix sidebar / SUMMARY
    V6.5.7 Auditoría de consistencia
```


### Auditoría de consistencia aplicada

- Se retiraron del changelog histórico las entradas prematuras de versiones posteriores, porque este paquete corresponde a la línea `V6.5.7`.
- Se agregó `Assassin’s Creed II` a la saga `Assassin’s Creed`.
- Se corrigieron conteos y listas de `Estrategia`, `Gestión` e `Internet Persistente`.
- Se agregaron los juegos faltantes de `Internet Persistente`: `Delta Force`, `Natural Selection 2`, `STALCRAFT: X` y `The Mean Greens - Plastic Warfare`.
- Se ordenaron alfabéticamente las listas visibles afectadas.
- Se agregó una página técnica específica: `V6.5.7 Auditoría de consistencia`.

### Resultado

El sidebar quedó más limpio, con menos ruido visual y sin submenús colgados de páginas incorrectas.

---

## V6.5.9 — Perfiles personales

**Objetivo:** separar la capa personal de Daniel de la biblioteca familiar global.

Cambios principales:

- Se reemplazó la rama global `V. Juegos clave` por `V. Perfiles personales`.
- La antigua lectura de juegos clave se migró al perfil de Daniel.
- Se crearon perfiles plantilla para Jesse y Jovan.
- Se movió la galería de assets a `07-juegos`, porque es global/técnica.
- Se actualizaron scripts para que las fichas clave se generen dentro de `05-perfiles/daniel`.
- Se agregó regla explícita: favoritos, backlog, mood y énfasis emocional deben vivir por persona.

---

## V6.5.8 — Acciones Steam y limpieza visual

**Objetivo:** permitir acciones directas hacia Steam desde las fichas del mdBook y hacer la lectura menos pesada.

### Cambios principales

- Se agregaron botones `Jugar`, `Instalar` y `Tienda` a las fichas de juego generadas.
- Se actualizó el generador `scripts/04-generate-game-pages.ps1` para conservar esos botones al regenerar.
- Se agregaron acciones Steam a las fichas extendidas de juegos clave.
- Se actualizó `scripts/13-generate-extended-key-sheets.ps1` para conservar acciones Steam en fichas extendidas.
- Se agregó una pasada de CSS para legibilidad:
  - más aire vertical;
  - bloques de código más respirables;
  - tablas menos comprimidas;
  - ancho de lectura más controlado;
  - botones de acción visualmente consistentes.
- Se corrigió una línea pegada en `SUMMARY.md` entre `Yu-Gi-Oh!` y `Géneros mecánicos`.

### Resultado

El mdBook queda más cómodo para uso diario: desde una ficha puedes abrir Steam para jugar, instalar o consultar la tienda, y la vista general queda menos saturada.


# 5. Comandos principales actuales

## Full sync seguro

```powershell
.\\scripts\\05-run-full-sync.ps1 -DiscoverFromMarkdown
```

## Solo regenerar visuales

```powershell
.\\scripts\\04-generate-game-pages.ps1
.\\scripts\\06-update-key-game-pages.ps1
.\\scripts\\07-generate-collection-tooltips.ps1
.\\scripts\\10-generate-assets-gallery.ps1
```

## Reparar auxiliares

```powershell
.\\scripts\\09-repair-mdbook-pages.ps1
```

## Validar rutas absolutas

```powershell
.\\scripts\\08-export-local-assets-inventory.ps1
.\\scripts\\99-validate-project-paths.ps1
```

## Levantar mdBook

```powershell
mdbook serve --open
```

## Levantar en red local

```powershell
mdbook serve --hostname 0.0.0.0 --port 3000
```

---

# 6. Estado recomendado

| Versión | Uso recomendado |
|---|---|
| V3.3.4 Markdown | Documento maestro plano / referencia |
| V6.5.4 mdBook | Base estable navegable previa |
| V6.5.5 mdBook | V6.5.4 + changelog histórico |
| V6.5.7 mdBook | Base estable previa con sidebar/SUMMARY y auditoría de consistencia |
| V6.5.8 mdBook | Acciones Steam y limpieza visual |
| V6.5.13 mdBook | Base estable actual con Pozo + MRD como secciones propias |

**Recomendación:** usar **V6.5.13** como baseline actual.

---

# 7. Pendientes sanos para futuras versiones

Ideas no urgentes:

- Generar páginas visuales por colección, no solo tooltips.
- Crear dashboard principal de biblioteca.
- Integrar SteamGridDB animado con criterio selectivo.
- Agregar filtros/búsqueda custom en galería.
- Exportar una versión PDF/estática pulida.
- Hacer una página de “qué jugar hoy” con reglas/mood.




## V6.5.13 — MRD como sección propia + veredicto duro

### Cambios

- `ZZZ) MRD` deja de ser una página técnica suelta y pasa a sección propia.
- Se agregó inventario completo de `ZZZ) MRD` con **57 juegos** desde captura.
- Se agregó columna **¿Vale la pena siquiera considerarlo?** con veredictos iniciales:
  - `✅ Sí, candidato real`
  - `🟨 Quizá, revisar primero`
  - `🧪 Solo curiosidad / baja prioridad`
  - `🟥 No priorizar`
- Se agregó página de criterios para diferenciar MRD de El Pozo.
- Se conserva la regla: MRD es cuarentena dura y no debe contaminar colecciones limpias.

### Archivos principales

- `src/02-colecciones/mrd/index.md`
- `src/02-colecciones/mrd/inventario-57.md`
- `src/02-colecciones/mrd/criterios-de-evaluacion.md`
- `data/mrd-inventario-v6-5-13.json`
- `data/v6-5-13-mrd-inventario-summary.json`


## V6.5.12 — El Pozo como sección propia + veredicto de prueba

### Cambios

- `ZZZ) El Pozo` deja de ser una página técnica suelta y pasa a sección propia.
- Se agregó inventario completo de `ZZZ) El Pozo` con **185 juegos** desde captura.
- Se agregó columna **¿Vale la pena probarlo?** con veredictos iniciales:
  - `✅ Sí, candidato real`
  - `🟨 Quizá, revisar primero`
  - `🧪 Solo curiosidad / baja prioridad`
  - `🟥 No priorizar`
- Se agregó página de criterios para evitar que El Pozo contamine colecciones limpias.
- Se conserva la regla: los juegos del Pozo no se mueven por etiqueta técnica; solo pasan si hay interés real, prueba satisfactoria, valor social o reputación suficiente.
- Se agregó `Dead as Disco` a `Música / Ritmo`, dejando la colección en **7 juegos**.

### Archivos principales

- `src/02-colecciones/pozo/index.md`
- `src/02-colecciones/pozo/inventario-185.md`
- `src/02-colecciones/pozo/criterios-de-evaluacion.md`
- `data/pozo-inventario-v6-5-12.json`
- `data/v6-5-12-pozo-inventario-summary.json`

## V6.5.11 — Sidebar de juegos compacto

**Objetivo:** quitar ruido visual en `VII. Juegos / Metadatos`.

Cambios principales:

- Se dejó de usar la vista global como lista gigante de juegos.
- Se creó navegación alfabética por páginas: `07-juegos/por-letra/`.
- Se conservaron anclas `game-meta-APP_ID` para compatibilidad con enlaces existentes.
- Se agregó saneamiento del `SUMMARY.md` para evitar que vuelvan a aparecer cientos de juegos en el sidebar.
- Se actualizó la lógica del generador de páginas para producir una vista compacta.

---
## V6.5.10 — Favoritos de Jovan

- Se registró la primera captura real de favoritos personales de Jovan.
- Se agregó `Cyberpunk 2077` manualmente a sus favoritos.
- Se reemplazó la plantilla de `Favoritos de Jovan` por una página con galería rápida, tabla alfabética y acciones Steam.
- Se actualizó el estado del perfil de Jovan a curaduría parcial iniciada.
- Se agregaron entradas mínimas de registry/targets para `Lossless Scaling` y `Wallpaper Engine`.


---

## V6.5.14 — Hotfix de registry, parser y ficha dinámica

- Se corrige el parser de tablas para detectar `Juego` aunque no sea la primera columna.
- Se limpia el registry de entradas corruptas `JuegoJuego`.
- Se regenera `review-needed` con pendientes reales desde Markdown.
- Se extienden tooltips a colecciones, estados, decisión y perfiles.
- Se agrega ficha dinámica única por `steamAppId`.
- Se arregla `Dead as Disco` dentro de `Música / Ritmo` con 7 juegos.
