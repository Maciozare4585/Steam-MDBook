# 🩹 V6.5.6 — Fix script de galería automática

Esta versión corrige que `10-generate-assets-gallery.ps1` no venía incluido en la V6.5.5, aunque el usuario intentara ejecutarlo.

## Problema

La V6.5.5 agregó el changelog usando como base una rama que no tenía el script de galería.
Por eso este comando fallaba:

```powershell
.\scripts\10-generate-assets-gallery.ps1
```

## Solución

Se agregó nuevamente:

```text
scripts/10-generate-assets-gallery.ps1
```

y se regeneró:

```text
src/05-juegos-clave/galeria-assets-generada.md
```

## Comando

```powershell
.\scripts\10-generate-assets-gallery.ps1
```
