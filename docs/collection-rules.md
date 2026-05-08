# Reglas de colecciones automáticas V6.6.0

`data/collection-rules.json` define cómo convertir metadata en colecciones.

## Modos

| Modo | Uso |
|---|---|
| `auto` | Se puede aplicar automáticamente. |
| `suggest` | Se propone como sugerencia y requiere confirmación. |
| `manual_only` | Nunca se aplica automáticamente. |

## Principio de seguridad

Nada debe salir de `ZZZ) El Pozo` o `ZZZ) MRD` automáticamente. Esas secciones funcionan como cuarentena. El sistema solo debe sugerir promoción.

## Ejemplo

```json
{
  "id": "auto-sin-terminar",
  "collection": "1) SIN TERMINAR",
  "mode": "auto",
  "conditions": {
    "playerState.checkboxes.started": true,
    "playerState.checkboxes.finishedMainStory": false,
    "playerState.checkboxes.abandoned": false
  }
}
```
