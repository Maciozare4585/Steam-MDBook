# 🩹 V6.5.7 — Fix sidebar / SUMMARY

Esta versión corrige el problema visual del sidebar donde los templates quedaron anidados debajo de `V6.5.3 Tooltips flotantes`.

## Problema

En `src/SUMMARY.md`, los archivos de:

```text
06-mantenimiento/templates/*.md
```

quedaron indentados como hijos del último item de mantenimiento visible:

```text
V6.5.3 Tooltips flotantes
```

Por eso mdBook mostraba cosas como:

```text
7.14. V6.5.3 Tooltips flotantes
  7.14.1 Template de mood nuevo
  7.14.2 Template de selector anti-parálisis
```

## Solución

Se reconstruyó manualmente el bloque:

```text
VI. Mantenimiento
```

para que quede así:

```text
VI. Mantenimiento
  Log de cambios histórico
  Sugerencias futuras
  Regla final resumida
  Templates copiables
    Template de mood nuevo
    Template de selector anti-parálisis
    ...
  Automatización de imágenes Steam
  Automatización imágenes: Registry + SGDB
  V6.4 Registry limpio
  ...
  V6.5.7 Fix sidebar / SUMMARY
```

## Regla para futuras versiones

Cuando se agregue una página nueva a mantenimiento, revisar que su indentación sea:

```md
  - [Página](06-mantenimiento/pagina.md)
```

Y que los templates solo vivan bajo:

```md
  - [Templates copiables](06-mantenimiento/templates.md)
    - [Template ...](06-mantenimiento/templates/...)
```

## Comando

Después de aplicar:

```powershell
mdbook serve --open
```

Si el sidebar conserva estado visual viejo:

```text
Ctrl + F5
```


---

## Ajuste adicional dentro de V6.5.7

Se organizó `VI. Mantenimiento` para que el sidebar no quede saturado.

Nueva agrupación:

```text
VI. Mantenimiento
  Log de cambios histórico
  Sugerencias futuras
  Regla final resumida
  Templates copiables
  Automatización
  Historial técnico de versiones
```

Las páginas técnicas `V6.x` ahora cuelgan de:

```text
Historial técnico de versiones
```

y los documentos de automatización cuelgan de:

```text
Automatización
```
---

## Ajuste adicional de persistencia del sidebar

Además del arreglo de jerarquía del `SUMMARY.md`, esta revisión agrega:

```text
theme/sidebar-persist.js
```

y registra el script en `book.toml`:

```toml
additional-js = ["theme/game-tooltips.js", "theme/sidebar-persist.js"]
```

Objetivo: conservar el ancho manual del sidebar al cambiar de página o refrescar el mdBook.
