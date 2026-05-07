# V6.5.8 — Acciones Steam y limpieza visual

## Objetivo

Hacer que el mdBook sea más práctico para abrir juegos desde Steam y reducir la sensación de lectura pesada/desacomodada.

## Cambios principales

- Se agregaron acciones rápidas de Steam en las fichas de juego:
  - `Jugar` usando `steam://run/APP_ID`.
  - `Instalar` usando `steam://install/APP_ID`.
  - `Tienda` usando `https://store.steampowered.com/app/APP_ID`.
- Se actualizaron las páginas generadas de `src/07-juegos`.
- Se actualizó `scripts/04-generate-game-pages.ps1` para que las acciones Steam se conserven al regenerar metadatos.
- Se actualizaron las fichas extendidas de juegos clave para incluir acciones rápidas.
- Se actualizó `scripts/13-generate-extended-key-sheets.ps1` para conservar esas acciones al regenerar fichas extendidas.
- Se agregó una pasada CSS de legibilidad:
  - ancho de lectura más controlado;
  - más aire entre títulos, párrafos y tablas;
  - bloques de código más respirables;
  - tablas con padding más consistente;
  - botones visuales uniformes para acciones Steam.
- Se corrigió una línea pegada en `SUMMARY.md` entre `Yu-Gi-Oh!` y `Géneros mecánicos`.
- Se retiró el rastro visual `V6.5.9` que quedaba en un comentario de CSS heredado.

## Limitación conocida

El mdBook sigue siendo estático. No puede detectar en vivo si un juego está instalado.

Por eso se muestran tres acciones explícitas:

| Acción | Uso |
|---|---|
| `Jugar` | Pide a Steam lanzar el juego por `APP_ID`. |
| `Instalar` | Pide a Steam abrir el flujo de instalación. |
| `Tienda` | Abre la página del juego en Steam Store. |

## Siguiente mejora posible

Crear un script PowerShell que lea `libraryfolders.vdf` y `appmanifest_APPID.acf` para generar un JSON de estado instalado/no instalado.

Eso permitiría mostrar badges como:

- `Instalado`
- `No instalado`
- `Launcher externo`
- `Sin App ID`

## Resultado esperado

La versión queda como base más cómoda para uso diario: menos pesada visualmente y con acciones directas para pasar de la ficha del mdBook al cliente de Steam.
