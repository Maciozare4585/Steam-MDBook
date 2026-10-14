@echo off
powershell -ExecutionPolicy Bypass -File "%~dp000-reset-discovery-state.ps1" %*
