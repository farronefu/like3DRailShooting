@echo off
setlocal
cd /d "%~dp0"
set "VECTOR_PYTHON=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if exist "%VECTOR_PYTHON%" (
  "%VECTOR_PYTHON%" tools\serve.py --open
) else (
  python tools\serve.py --open
)
if errorlevel 1 pause
endlocal
