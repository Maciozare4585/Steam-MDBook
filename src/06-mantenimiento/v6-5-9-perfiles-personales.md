# V6.5.9 — Perfiles personales

## Objetivo

Encapsular la antigua sección **Juegos clave** para que el énfasis personal de Daniel no funcione como criterio global de la biblioteca familiar.

## Cambios principales

| Área | Cambio |
|---|---|
| `05-juegos-clave` | Se retiró como rama global |
| `05-perfiles` | Nueva rama para perfiles personales |
| Daniel | Recibe la antigua capa de juegos clave, fichas extendidas y notas personales |
| Jesse | Se agrega perfil plantilla pendiente de curaduría |
| Jovan | Se agrega perfil plantilla pendiente de curaduría |
| Galería de assets | Se mueve a `07-juegos`, porque es técnica/global, no personal |
| Scripts | Se actualizan rutas para generar fichas clave en el perfil de Daniel |
| `SUMMARY.md` | Se reemplaza `V. Juegos clave` por `V. Perfiles personales` |

## Regla nueva

La biblioteca familiar se divide en dos capas:

| Capa | Función |
|---|---|
| Global | Clasificar juegos por saga, género, experiencia, estado técnico o metadatos |
| Personal | Registrar qué significa un juego para Daniel, Jesse o Jovan |

## Estado de perfiles

| Persona | Estado |
|---|---|
| Daniel High | Perfil activo, migrado desde Juegos clave |
| Jesse | Plantilla pendiente |
| Jovan | Plantilla pendiente |

## Validación

- `SUMMARY.md` actualizado.
- Galería global separada de perfiles.
- Rutas de imágenes ajustadas por profundidad nueva.
- Scripts actualizados para no regenerar la rama vieja `05-juegos-clave`.
