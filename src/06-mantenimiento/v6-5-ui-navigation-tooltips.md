# 🧭 V6.5 — Navegación, rutas relativas y previews

Esta versión se enfoca en UI/UX del mdBook y en higiene de rutas.

## Cambios aplicados

| Área | Cambio |
|---|---|
| Sidebar | `SUMMARY.md` deja de usar headers `# I...` y usa capítulos padre reales |
| Sidebar | Juegos clave individuales salen del sidebar principal |
| mdBook | `book.toml` conserva `[output.html.fold] enable = true` y `level = 0` |
| Fichas clave | Se reemplazan placeholders por imágenes por Steam App ID |
| Páginas genéricas | Se corrige el generador para no imprimir expresiones PowerShell literales |
| Colecciones | Se agregan tooltips visuales al pasar el mouse sobre juegos en tablas |
| Rutas | Se agregan helpers para rutas relativas al proyecto y relativas al `.md` |
| Validación | Nuevo `scripts/99-validate-project-paths.ps1` |
| Assets | `local-assets-existing.csv` ahora usa `ProjectRelativePath` |

## Comandos útiles

### Sync normal

```powershell
.\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown
```

### Regenerar solo páginas

```powershell
.\scripts\04-generate-game-pages.ps1
.\scripts\06-update-key-game-pages.ps1
.\scripts\07-generate-collection-tooltips.ps1
```

### Exportar inventario de assets sin rutas absolutas

```powershell
.\scripts\08-export-local-assets-inventory.ps1
```

### Validar que no haya rutas absolutas persistidas

```powershell
.\scripts\99-validate-project-paths.ps1
```

Modo estricto:

```powershell
.\scripts\99-validate-project-paths.ps1 -Strict
```

## Nota de diseño

La galería global sigue existiendo como herramienta técnica, pero las colecciones ahora ganan contexto visual mediante hover previews.
Los juegos clave individuales siguen existiendo como páginas, pero se acceden desde su índice visual, no desde el sidebar.
