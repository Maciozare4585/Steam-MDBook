# 🧩 Template de metadata DLC por iconos

Este template es para editar `data/games-metadata.json` cuando una ficha necesita indicar el estado de sus DLC.

La regla visual es simple: **el estado del DLC se expresa con iconos**, no con checkbox ni texto visible por fila. Un DLC puede tener **más de un icono** usando `markers`.

## Bloque copiables

```json
"dlcInfo": {
  "hasDlc": true,
  "totalDlcCount": 2,
  "ownedDlcCount": 1,
  "missingDlcCount": 1,
  "ownershipStatus": "partial",
  "ownershipSummary": "DLC auditado manualmente desde captura/lista local.",
  "missingNotes": [
    "Revisar si el season pass conviene comprarlo en oferta."
  ],
  "manualSource": "steam-library-capture",
  "lastManualUpdateAt": "2026-05-13T00:00:00Z",
  "dlcs": [
    {
      "appId": 123456,
      "title": "Nombre del DLC principal",
      "type": "dlc",
      "markers": ["owned", "pass"],
      "important": true,
      "isFree": false,
      "price": null,
      "releaseDate": null,
      "storeUrl": "https://store.steampowered.com/app/123456",
      "source": "manual",
      "lastSyncedAt": null
    },
    {
      "appId": 654321,
      "title": "Original Soundtrack",
      "type": "dlc",
      "markers": ["missing", "soundtrack"],
      "important": false,
      "isFree": false,
      "price": null,
      "releaseDate": null,
      "storeUrl": "https://store.steampowered.com/app/654321",
      "source": "manual",
      "lastSyncedAt": null
    }
  ]
}
```

## Valores de `markers`

| Marker | Icono | Uso |
|---|---:|---|
| `owned` | ✅ | Lo tenemos. |
| `missing` | ⬜ | No lo tenemos / pendiente. |
| `skip` | 🚫 | No comprar / descartar. |
| `free` | 🆓 | Contenido gratuito. |
| `pass` | 🧩 | Season pass, expansion pass, pack o expansión grande. |
| `soundtrack` | 🎵 | Banda sonora / OST. |
| `artbook` | 📘 | Artbook, libro digital o material documental. |
| `cosmetic` | 🎨 | Skin, outfit, personaje cosmético o cosmetic pack. |
| `currency` | 💰 | Moneda, créditos, gems, consumibles o boosts. |

## Regla recomendada

Usa el primer icono como estado principal y los demás como tipo/contexto:

```json
"markers": ["owned", "pass"]
"markers": ["missing", "soundtrack"]
"markers": ["skip", "currency"]
"markers": ["free", "cosmetic"]
```

El campo legado `marker` puede seguir existiendo por compatibilidad, pero el template manual debe usar `markers`.

Después de editar metadata, regenera el índice:

```powershell
.\scripts\15-build-games-index-with-metadata.ps1
mdbook clean
mdbook serve --open
```
