# 16. 💡 Sugerencias futuras

Estas no son colecciones activas. Son candidatas posibles si algún día aportan valor real.

| Colección sugerida | Nivel | Juegos candidatos | Duplicado nutritivo | Veredicto |
|---|---|---|---|---|
| 🌌 Postapocalíptico | Tema / ambientación | Fallout, Metro, S.T.A.L.K.E.R., Mad Max, Dying Light, Project Zomboid, This War of Mine | Sí, si representa antojo real | Primera candidata temática, no obligatoria |
| 🃏 Cartas / Deckbuilder | Género mecánico / experiencia | Balatro, Slay the Spire, Yu-Gi-Oh!, GWENT, Shadowverse | Sí | Buena futura si crece o si se usa como filtro |
| 👊 Beat ’em up / Brawler | Género mecánico | Castle Crashers, Fight’N Rage, Watchmen, Broforce | Sí | No urgente; YYY/Peleas lo absorben por ahora |
| 🧱 Pixel Art | Tema / estética visual | Stardew Valley, Terraria, Celeste, Dead Cells, Blasphemous, Hotline Miami | Solo si se usa como antojo visual | Candidata estética; alto riesgo de volverse etiqueta gigante |
| 🧟 Zombies | Tema / ambientación | Left 4 Dead, Project Zomboid, Dying Light, Resident Evil, Zombie Army | Solo si se usa como antojo | Menos prioritaria que Postapocalíptico |
| 🎯 Prioridad actual / Próximos | Estado / selector | Top 10-15 juegos de 3) Lo quiero jugar | Sí | Útil si 109 juegos en Nuevo causan parálisis |
---

## Ideas técnicas para próximas versiones

Estas ideas ya no son solo colecciones; son mejoras posibles del sistema como herramienta.

| Idea | Tipo | Valor | Complejidad | Nota |
|---|---|---|---|---|
| Buscador local en tiempo real | UI / navegación | Filtrar por nombre, saga, género, estado, perfil, DLC y multiplayer sin recargar. | Media | Puede consumir `games-index.json` directamente. |
| Selector “¿qué juego pongo hoy?” | Recomendación | Reduce parálisis de decisión usando energía, tiempo, mood y personas disponibles. | Media-alta | Aprovecha `recommendationMetadata`. |
| Vista comparativa Daniel/Jesse/Jovan | Perfiles | Ver favoritos, pendientes, coincidencias y juegos familiares compartidos. | Media | Útil para biblioteca familiar real. |
| Auditor de metadata | Mantenimiento | Detectar juegos sin imagen, sin género, sin profile metadata, sin DLC sync, etc. | Media | Puede generar `data/audit-report.json` y una página mdBook. |
| Editor visual local de metadata | Tooling | Cambiar `markers`, estado personal, prioridad o notas sin editar JSON a mano. | Alta | Podría ser una mini app estática o script con UI. |
| Alertas de DLC faltantes | DLC / precios | Ver DLC `missing` o `skip` y priorizar ofertas. | Alta | Requiere precios actuales y cuidado con rate limits. |
| Script `19-add-new-games.ps1` | Automatización | Agregar títulos nuevos, resolver ID, bajar assets, metadata y DLC en una sola entrada. | Media | Evita tocar varias fases manualmente. |
| Notas de sesión por perfil | Perfil / tracking | Registrar “lo jugué hoy”, avance, próximos pasos y fricción. | Media | Base para PlayNext/SteamCopilot. |
| Vista TV / sesión familiar | UI | Pantalla limpia para decidir juegos en sala o con amigos. | Media | Prioriza portada, jugadores, tiempo y estado. |
| Exportar resumen limpio | Portabilidad | Generar Markdown/HTML compacto para compartir fuera del mdBook. | Baja-media | Útil para respaldos y documentación externa. |
