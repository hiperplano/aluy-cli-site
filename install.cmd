@echo off
REM ===========================================================================
REM  aluy - bootstrap (Windows / cmd.exe)
REM    curl -fsSL https://<host>/install.cmd -o "%TEMP%\aluy.cmd" ^&^& "%TEMP%\aluy.cmd"
REM
REM  Minimo de proposito: so garante o Node e instala o pacote. Todo o resto
REM  (splash, idioma, backend, provider, chave, modelo, sidecars) e o
REM  `aluy onboard` (Node + Ink). ASCII puro de proposito (o .bat nao sofre o
REM  encoding do .ps1/irm; a UI bonita vive no onboard, em Node).
REM ===========================================================================
setlocal
chcp 65001 >nul
if defined ALUY_PKG (set "PKG=%ALUY_PKG%") else (set "PKG=@aluy/cli")

REM 1) Node (unico pre-requisito)
echo [*] Passo 1/2 - verificando o Node ^(o aluy roda sobre ele^)...
where node >nul 2>nul
if errorlevel 1 (
  where winget >nul 2>nul
  if errorlevel 1 (
    echo [x] Node.js nao encontrado. Instale o Node ^>= 20 ^(https://nodejs.org^) e rode de novo.
    exit /b 1
  )
  echo     Node nao encontrado - baixando o Node LTS via winget. A barra abaixo e o
  echo     download do Node ^(pode levar alguns minutos^).
  winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
)

REM 2) instala. Explica O QUE a barra do npm baixa (senao parece "node" cru e opaco).
echo [*] Passo 2/2 - baixando o aluy e seus componentes...
echo       . interface de terminal ^(Ink/React^)   . acesso seguro a credenciais ^(keychain^)
echo       . protocolo de ferramentas ^(MCP^). A barra abaixo e o npm baixando esses
echo       pacotes ^(alguns sao binarios nativos do Node^) - costuma levar 1-2 min.
call npm install -g %PKG%
where aluy >nul 2>nul
if errorlevel 1 (
  echo [x] aluy nao ficou no PATH. Feche e reabra o terminal e rode: aluy onboard
  exit /b 1
)

REM 3) entrega pro ONBOARD (Node/Ink). No cmd o stdin JA e o console, entao o Ink
REM    le o teclado direto (sem Start-Process). Depois entra na sessao.
cls
call aluy onboard
REM TURBO: provisiona os sidecars via o agente (no-op se o perfil for leve).
REM No Windows nao ha artefato pinado: o agente instala (winget/pip). Respeita o perfil.
cls
call aluy bootstrap --agent
REM tela limpa antes de abrir a sessao (cada etapa comeca do zero, sem ruido acumulado).
cls
aluy
endlocal
