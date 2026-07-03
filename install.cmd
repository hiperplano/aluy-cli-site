@echo off
REM ===========================================================================
REM  aluy - bootstrap (Windows / cmd.exe)
REM    curl -fsSL https://aluy.dev/install.cmd -o "%TEMP%\aluy.cmd" ^&^& "%TEMP%\aluy.cmd"
REM
REM  Minimal by design: this only ensures Node exists and installs the package.
REM  Everything else (splash, language, backend, provider, key, model, sidecars)
REM  is `aluy onboard` (Node + Ink). The VISUAL mirrors the brand: bi-tone Aluy
REM  wordmark + amber numbered steps, rendered with ANSI truecolor on Windows 10+
REM  (VT). Degrades clean to plain ASCII markers on older consoles.
REM ===========================================================================
setlocal EnableExtensions
chcp 65001 >nul
if defined ALUY_PKG (set "PKG=%ALUY_PKG%") else (set "PKG=@hiperplano/aluy-cli")

REM -- Brand palette + ANSI VT detection (truecolor works on Windows 10+) -------
set "ANSI=0"
for /f "tokens=2 delims=[]" %%v in ('ver') do set "VERSTR=%%v"
for /f "tokens=2 delims= " %%v in ("%VERSTR%") do set "VERNUM=%%v"
for /f "tokens=1 delims=." %%v in ("%VERNUM%") do set "MAJOR=%%v"
if not defined MAJOR set "MAJOR=0"
if %MAJOR% GEQ 10 set "ANSI=1"

REM defaults (no color / ASCII markers)
set "AMBER=" & set "LUY=" & set "DIM=" & set "BOLD=" & set "RESET="
set "TRI=[*]" & set "CK=[ok]" & set "CR=[x]"

if "%ANSI%"=="1" for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
if "%ANSI%"=="1" (
  set "AMBER=%ESC%[38;2;221;161;63m"
  set "LUY=%ESC%[38;2;200;130;30m"
  set "DIM=%ESC%[38;2;125;116;104m"
  set "BOLD=%ESC%[1m"
  set "RESET=%ESC%[0m"
  set "TRI=%ESC%[38;2;221;161;63m▸%ESC%[0m"
  set "CK=%ESC%[38;2;122;184;120m✓%ESC%[0m"
  set "CR=%ESC%[38;2;207;83;83m✗%ESC%[0m"
)

REM -- wordmark (ANSI/truecolor on Windows 10+; plain text otherwise) ----------
echo(
if "%ANSI%"=="1" (
  echo   %AMBER%      ██      %RESET% %LUY%██                %RESET%
  echo   %AMBER%     ████     %RESET% %LUY%██  ██  ██  ██  ██%RESET%
  echo   %AMBER%   ███  ███   %RESET% %LUY%██  ██  ██  ██  ██%RESET%
  echo   %AMBER% ███      ███ %RESET% %LUY%██  ██  ██   █████%RESET%
  echo   %AMBER%███        ███%RESET% %LUY%██   █████      ██%RESET%
  echo   %AMBER%              %RESET% %LUY%            ████  %RESET%
  echo.
  echo   %DIM%terminal agent · runs on your machine · with your own LLM provider%RESET%
) else (
  echo   Aluy
)
echo(

REM 1) Node (only prerequisite)
echo(
echo   %BOLD%%AMBER%1/2%RESET%  Node - aluy runs on it
where node >nul 2>nul
if errorlevel 1 (
  where winget >nul 2>nul
  if errorlevel 1 (
    echo   %CR% Node.js not found. Install Node ^>= 20 ^(https://nodejs.org^) and run again.
    exit /b 1
  )
  echo   %TRI% Node not found - installing Node LTS via winget.
  echo       %DIM%the bar below is the Node download ^(may take a few minutes^).%RESET%
  winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
)

REM 2) install. Explain WHAT the npm bar is downloading (else it looks opaque).
echo(
echo   %BOLD%%AMBER%2/2%RESET%  downloading aluy and its components
echo       %DIM%- terminal UI (Ink/React)   - secure credential access (keychain)%RESET%
echo       %DIM%- tool protocol (MCP)%RESET%
echo       %DIM%the bar below is npm downloading these packages (some are native Node%RESET%
echo       %DIM%binaries) - usually takes 1-2 min.%RESET%
call npm install -g %PKG%
where aluy >nul 2>nul
if errorlevel 1 (
  REM First global install: the npm prefix may not be on this session's PATH yet.
  REM Prepend the npm bin dir (parity with install.ps1 / install.sh).
  for /f "delims=" %%P in ('npm config get prefix 2^>nul') do set "PATH=%%P;%PATH%"
)
where aluy >nul 2>nul
if errorlevel 1 (
  echo   %CR% aluy is not on PATH. Close and reopen the terminal, then run: aluy onboard
  exit /b 1
)
echo   %CK% aluy installed.

REM 3) hand off to ONBOARD (Node/Ink). In cmd, stdin IS already the console, so Ink
REM    reads the keyboard directly (no Start-Process). Then open the session.
cls
call aluy onboard
REM TURBO: provisions the sidecars via the agent (no-op for a light profile). On
REM Windows there is no pinned artifact: the agent installs (winget/pip). Honors the profile.
cls
call aluy bootstrap --agent
REM clear before the session (each step starts clean, no accumulated noise).
cls
aluy
endlocal
