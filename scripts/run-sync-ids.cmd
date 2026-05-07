@echo off
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp001-sync-steam-ids.ps1" %*
