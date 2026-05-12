<#
.SYNOPSIS
    Registra nota técnica offline de reparación V6.5.14.
.DESCRIPTION
    Script auxiliar histórico usado para dejar rastro de reparación offline. No forma parte del pipeline diario.
.EXAMPLE
    .\scripts\12-v6-5-14-offline-repair-note.ps1
#>
# V6.5.14
# Esta versión incluye una reparación offline aplicada al ZIP entregado:
# - registry limpio
# - review-needed regenerado
# - tooltips extendidos
# - ficha dinámica con src/assets/data/games-index.json
#
# Para cambios futuros usa:
# .\scripts\01-sync-steam-ids.ps1 -DiscoverFromMarkdown
# .\scripts\04-generate-game-pages.ps1
# .\scripts\07-generate-collection-tooltips.ps1
