# 🖼️ V6.5.4 — Galería automática de assets

Esta versión corrige la página placeholder de `05-juegos-clave/galeria-assets-generada.md`.

## Problema

La galería automática seguía mostrando instrucciones del pipeline viejo:

```powershell
.\scripts\sync-game-registry-and-assets.ps1 -UpdateMarkdownPages
```

Ese script ya no era la ruta principal en la rama V6.5.x.

## Solución

Se agregó/generó:

```text
scripts/10-generate-assets-gallery.ps1
src/05-juegos-clave/galeria-assets-generada.md
```

La galería lee:

```text
data/steam-games-registry.json
```

y crea cards visuales que enlazan a:

```text
../07-juegos/index.html#game-meta-<steamAppId>
```

## Comando

```powershell
.\scripts\10-generate-assets-gallery.ps1
```
