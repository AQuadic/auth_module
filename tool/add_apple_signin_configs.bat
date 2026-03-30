@echo off
setlocal

if "%~1"=="" (
  echo Usage: add_apple_signin_configs.bat ^<path-to-AndroidManifest.xml^>
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0add_apple_signin_configs.ps1" -ManifestPath "%~1"
exit /b %ERRORLEVEL%
