# Flujo Git recomendado

Este proyecto está preparado para versionarse sin subir salida compilada ni assets pesados.

## Archivos que sí deben versionarse

- `book.toml`
- `README.md`
- `src/**`
- `theme/**`
- `scripts/**`
- `data/**` salvo reportes generados ignorados
- `docs/**`
- `.gitignore`
- `.gitattributes`
- `.editorconfig`

## Archivos que no deben subirse

- `book/`
- `src/assets/games/`
- `src/assets/steam/`
- `src/assets/steamgriddb/`
- `*.zip`
- reportes de assets generados

## Inicializar repo limpio

```powershell
git init
git add .
git commit -m "V6.5.14 - proyecto mdBook limpio para Git"
```

## Conectar con GitHub

```powershell
git branch -M main
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git push -u origin main
```

## Validación básica antes de commit

```powershell
git status
Test-Path .\src\assets\data\games-index.json
Test-Path .\src\07-juegos\detalle.md
Select-String -Path .\src\SUMMARY.md -Pattern "detalle.md"
```

## Build local

```powershell
mdbook clean
mdbook build
mdbook serve
```
