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
REM PKG = o pacote (mensagens e limpeza); SPEC = o que vai no `npm install`.
REM Separados DE PROPOSITO: o `@latest` so entra no DEFAULT - se alguem fixou
REM ALUY_PKG para testar uma versao especifica, grudar `@latest` sobrescreveria a
REM escolha. `npm i -g pkg` ja significa `pkg@latest`; escrever explicito deixa a
REM intencao no comando (conferido no registro: o dist-tag `latest` aponta para a
REM rc mais nova, entao NAO e o registro que entrega versao antiga).
set "PKG=@hiperplano/aluy-cli"
set "SPEC=@hiperplano/aluy-cli@latest"
if defined ALUY_PKG set "PKG=%ALUY_PKG%"
if defined ALUY_PKG set "SPEC=%ALUY_PKG%"

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
  REM Wordmark IDENTICO ao do CLI (wordmark-3d.ts) — a marca plana daqui divergia da
  REM que o usuario ve ao abrir o aluy. Uma cor so: a sombra e a marca sao o mesmo
  REM ambar em intensidades diferentes, e isso ja esta no desenho (bloco cheio vs meio-tom).
  REM Depende do `chcp 65001` la em cima — sem ele o cmd le em cp850 e isto vira lixo.
  echo   %AMBER%      ██       ██%RESET%
  echo   %AMBER%     ████      ██▒ ██  ██  ██  ██%RESET%
  echo   %AMBER%   ███▒▒███    ██▒ ██▒ ██▒ ██▒ ██▒%RESET%
  echo   %AMBER% ███▒▒▒  ▒███  ██▒ ██▒ ██▒  █████▒%RESET%
  echo   %AMBER%███▒▒      ███ ██▒  █████▒   ▒▒██▒%RESET%
  echo   %AMBER% ▒▒▒        ▒▒▒ ▒▒   ▒▒▒▒▒  ████▒▒%RESET%
  echo   %AMBER%                             ▒▒▒▒%RESET%
  echo.
  echo   %DIM%terminal agent · runs on your machine · with your own LLM provider%RESET%
) else (
  echo   Aluy
)
echo(

REM -- TERMS OF USE --------------------------------------------------------------
REM Consent comes BEFORE any download - including step 1, which may install Node
REM via winget. "Before downloading the components" means before the first byte.
set "TERMS_URL=https://aluy.dev/termos.html"
if "%ALUY_ACCEPT_TERMS%"=="1" (
  echo       %DIM%terms accepted via ALUY_ACCEPT_TERMS=1 - %TERMS_URL%%RESET%
  goto :terms_ok
)
echo(
echo   %TRI% Terms of Use - %TERMS_URL%
echo       %DIM%* BETA software, provided "as is", WITHOUT warranty%RESET%
echo       %DIM%* runs on YOUR machine, under your responsibility%RESET%
echo       %DIM%* you use YOUR OWN provider credentials ^(BYO^); they never pass through us%RESET%
echo       %DIM%* free to use, including commercially; open-source, no charge%RESET%
echo(
set "TERMS_TRIES=0"

:terms_ask
set /a TERMS_TRIES+=1
REM Teto de tentativas: um console sem ninguem do outro lado devolve VAZIO para
REM sempre no `set /p` (nao da erro) - sem este teto o instalador giraria em laco
REM infinito. Cinco silencios nao e uma pessoa digitando; e uma maquina.
if %TERMS_TRIES% GTR 5 goto :terms_noanswer
set "TERMS_ANS="
set /p "TERMS_ANS=  accept the terms? [y] yes / [r] read in full / [n] no: "
if not defined TERMS_ANS goto :terms_ask
if /i "%TERMS_ANS%"=="y"    goto :terms_ok
if /i "%TERMS_ANS%"=="yes"  goto :terms_ok
if /i "%TERMS_ANS%"=="s"    goto :terms_ok
if /i "%TERMS_ANS%"=="r"    goto :terms_read
if /i "%TERMS_ANS%"=="read" goto :terms_read
if /i "%TERMS_ANS%"=="l"    goto :terms_read
if /i "%TERMS_ANS%"=="n"    goto :terms_no
if /i "%TERMS_ANS%"=="no"   goto :terms_no
echo       %DIM%answer y, r or n.%RESET%
goto :terms_ask

:terms_read
REM PowerShell existe em todo Windows suportado: usamos ele p/ baixar e tirar as
REM tags, imprimindo NO TERMINAL. Nao abrimos navegador de proposito - a janela
REM pode estar num RDP ou numa VM recem-criada sem browser configurado. Se a rede
REM falhar, cai no `start` (navegador) e, em ultimo caso, sobra a URL na tela.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $h=(Invoke-WebRequest -UseBasicParsing '%TERMS_URL%' -TimeoutSec 15).Content; $m=[regex]::Match($h,'(?s)<main>(.*?)</main>'); if($m.Success){$b=$m.Groups[1].Value}else{$b=$h}; $b=[regex]::Replace($b,'(?s)<(script|style)[^>]*>.*?</\1>',''); $b=[regex]::Replace($b,'<[^>]+>',''); $b=$b -replace '&amp;','&' -replace '&nbsp;',' '; foreach($l in ($b -split [char]10)){ $t=$l.Trim(); if($t -ne ''){ Write-Host ('  '+$t) } } }"
if errorlevel 1 start "" "%TERMS_URL%"
echo(
set "TERMS_TRIES=0"
goto :terms_ask

:terms_no
echo(
echo       %DIM%installation cancelled - nothing was downloaded.%RESET%
exit /b 1

:terms_noanswer
echo       %DIM%no answer received - proceeding implies ACCEPTING the terms above.%RESET%

:terms_ok
echo(
REM 1) Node (only prerequisite)
echo(
echo   %BOLD%%AMBER%1/2%RESET%  Node - aluy runs on it
where node >nul 2>nul
if not errorlevel 1 goto :node_found
where winget >nul 2>nul
if errorlevel 1 (
  echo   %CR% Node.js not found. Install Node ^>= 20 ^(https://nodejs.org^) and run again.
  exit /b 1
)
echo   %TRI% Node not found - installing Node LTS via winget.
echo       %DIM%the bar below is the Node download ^(may take a few minutes^).%RESET%
winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
REM O winget instala o Node mas NAO atualiza o PATH DESTA sessao. Sem isto, o
REM `npm install` la embaixo morria com "'npm' nao e reconhecido" - e o script SEGUIA
REM adiante, terminando com uma mensagem de sucesso sem ter instalado nada. O
REM install.ps1 ja recarregava o PATH depois do winget; aqui nao havia equivalente.
set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"
where node >nul 2>nul
if not errorlevel 1 goto :node_found
echo   %CR% Node was installed but is not visible in this session.
echo       %DIM%close this terminal, open a new one, and run the installer again.%RESET%
exit /b 1

:node_found
REM Versao minima - paridade com o install.ps1, que ja exigia Node ^>= 20. Um Node
REM antigo instala o pacote sem reclamar e so quebra ao ABRIR o aluy: o erro chega
REM tarde e sem relacao aparente com a instalacao. Se a leitura falhar, seguimos em
REM frente - nunca bloquear por nao ter conseguido MEDIR.
set "NODEMAJOR="
for /f "tokens=1 delims=." %%v in ('node -p process.version 2^>nul') do set "NODEMAJOR=%%v"
if not defined NODEMAJOR goto :node_ok
set "NODEMAJOR=%NODEMAJOR:v=%"
if %NODEMAJOR% LSS 20 (
  echo   %CR% Node %NODEMAJOR% is too old - aluy needs Node ^>= 20. See https://nodejs.org
  exit /b 1
)
:node_ok

REM 2) install. Explain WHAT the npm bar is downloading (else it looks opaque).
echo(
echo   %BOLD%%AMBER%2/2%RESET%  downloading aluy and its components
echo       %DIM%- terminal UI (Ink/React)   - secure credential access (keychain)%RESET%
echo       %DIM%- tool protocol (MCP)%RESET%
echo       %DIM%the bar below is npm downloading these packages (some are native Node%RESET%
echo       %DIM%binaries) - usually takes 1-2 min.%RESET%
REM Onde o npm VAI escrever. No Windows o prefix global E o proprio diretorio dos
REM atalhos - %APPDATA%\npm - e nao um `bin\` dentro dele; por isso o PATH recebe o
REM prefix cru. Guardamos ANTES do install para depois resolver o binario pelo caminho
REM ABSOLUTO, como o install.sh ja faz com "$BIN/aluy".
set "NPMPREFIX="
for /f "delims=" %%P in ('npm config get prefix 2^>nul') do set "NPMPREFIX=%%P"

call npm install -g "%SPEC%"
if not errorlevel 1 goto :npm_ok

REM DEFEITO REAL, capturado no log do dono: o `npm install` FALHOU e o script seguiu
REM ate imprimir "aluy installed". O npm nao conseguiu apagar a instalacao anterior
REM - EPERM em arquivos travados pelo Windows - e abortou com EEXIST no atalho
REM `%APPDATA%\npm\aluy`. A versao ANTIGA continuou no lugar, o `where aluy` achou
REM ELA, o instalador declarou sucesso e abriu a versao velha - e por isso que o
REM onboarding dele mostrava a tela de outra versao. Sem checar o errorlevel, QUALQUER
REM falha do npm virava sucesso silencioso.
echo(
echo   %TRI% npm failed - on Windows this is usually a locked previous install: EEXIST/EPERM.
echo       %DIM%removing the leftovers of the previous install and trying once more.%RESET%
REM Remedio que o proprio npm sugere ao dar EEXIST: remover o que sobrou e instalar de
REM novo. Apagamos SO o que e nosso - os tres atalhos `aluy*` e a pasta do pacote.
REM Nunca `--force`: aquilo manda o npm sobrescrever arquivo de qualquer dono, as cegas.
if defined NPMPREFIX del /f /q "%NPMPREFIX%\aluy" >nul 2>nul
if defined NPMPREFIX del /f /q "%NPMPREFIX%\aluy.cmd" >nul 2>nul
if defined NPMPREFIX del /f /q "%NPMPREFIX%\aluy.ps1" >nul 2>nul
if defined NPMPREFIX rd /s /q "%NPMPREFIX%\node_modules\%PKG:/=\%" >nul 2>nul
call npm install -g "%SPEC%"
if not errorlevel 1 goto :npm_ok

echo(
echo   %CR% npm could not install aluy - nothing was launched.
echo       %DIM%1. close every window running aluy or node - Windows locks those files%RESET%
echo       %DIM%2. delete "%NPMPREFIX%\aluy" and "%NPMPREFIX%\node_modules\@hiperplano"%RESET%
echo       %DIM%3. run again: npm install -g %SPEC%%RESET%
exit /b 1

:npm_ok
REM PATH: prepend SEMPRE o prefix do npm. Antes isto so acontecia quando o `where
REM aluy` FALHAVA - o inverso do necessario: havendo um `aluy` ANTIGO noutra pasta do
REM PATH, o `where` acha ELE, o prefix novo nunca entra na frente, e a sessao abre na
REM versao velha.
if defined NPMPREFIX set "PATH=%NPMPREFIX%;%PATH%"

REM Resolve o binario pelo caminho ABSOLUTO. Chamar `aluy` pelo nome entrega a decisao
REM ao PATH, que e exatamente onde mora o problema. O `where` so entra como ultimo
REM recurso - quando nem o prefix conseguimos ler.
set "ALUY="
if defined NPMPREFIX if exist "%NPMPREFIX%\aluy.cmd" set "ALUY=%NPMPREFIX%\aluy.cmd"
if not defined ALUY for /f "delims=" %%A in ('where aluy.cmd 2^>nul') do if not defined ALUY set "ALUY=%%A"
if defined ALUY goto :aluy_found
echo   %CR% aluy is not on PATH. Close and reopen the terminal, then run: aluy onboard
exit /b 1

:aluy_found
echo   %CK% aluy installed:
REM Imprime a versao RECEM-instalada. E o jeito mais barato de o usuario ver, na hora,
REM que nao esta abrindo uma instalacao velha - foi exatamente o que passou despercebido.
call "%ALUY%" --version

REM Instalacao ORFA sombreando a nova. No Windows e comum conviverem %APPDATA%\npm e um
REM prefix proprio: a antiga vence o PATH em qualquer terminal novo e o usuario roda a
REM versao velha sem perceber - reportando defeito ja corrigido. O install.sh avisa
REM disso desde a correcao #4; no Windows nao havia equivalente. Comparamos a PASTA, nao
REM o arquivo: o `where` lista `aluy` E `aluy.cmd` do MESMO diretorio, e isso e UMA
REM instalacao so. Avisamos com o comando exato; nao removemos nada por conta propria.
if not defined NPMPREFIX goto :shadow_done
set "OURDIR=%NPMPREFIX%\"
set "SHADOW="
for /f "delims=" %%A in ('where aluy 2^>nul') do if /i not "%%~dpA"=="%OURDIR%" set "SHADOW=1"
if not defined SHADOW goto :shadow_done
echo(
echo   %CR% there is ANOTHER aluy on your PATH:
for /f "delims=" %%A in ('where aluy 2^>nul') do if /i not "%%~dpA"=="%OURDIR%" echo       %%A
echo       %DIM%this install: %ALUY%%RESET%
echo       %DIM%the old one can shadow this one in other terminals - remove it with: npm rm -g %PKG%%RESET%
:shadow_done

REM O onboarding e Ink - React no terminal - e precisa de um CONSOLE de verdade. Com a
REM saida redirecionada para arquivo, ou num terminal que nao e console do Windows como
REM o Git Bash/MinTTY, `process.stdout.isTTY` e falso: o `aluy onboard` sai na hora
REM dizendo que precisa de terminal interativo, o `aluy` sai com "sem objetivo e sem
REM TTY", e a instalacao termina SEM configurar nada. Foi o que apareceu no log do dono.
REM Detectamos AQUI e dizemos o que fazer, em vez de encadear tres comandos que
REM desistem, cada um com uma linha cifrada.
node -e "if(!process.stdout.isTTY)process.exit(1);if(!process.stdin.isTTY)process.exit(1)"
if not errorlevel 1 goto :interactive
echo(
echo   %TRI% aluy is installed, but this terminal is not an interactive console.
echo       %DIM%open Command Prompt or Windows Terminal and run:  aluy onboard%RESET%
exit /b 0

:interactive
REM 3) hand off to ONBOARD (Node/Ink). In cmd, stdin IS already the console, so Ink
REM    reads the keyboard directly (no Start-Process). Then open the session.
REM NOTA: `cls` com a saida redirecionada nao limpa nada - escreve um form feed, 0x0C,
REM dentro do arquivo. E esse byte que aparecia como um simbolo estranho no comeco de
REM algumas linhas do log do dono; nao era defeito de codificacao das mensagens. So
REM chegamos aqui com console de verdade, entao aqui o `cls` limpa mesmo.
cls
call "%ALUY%" onboard
REM TURBO: provisions the sidecars via the agent (no-op for a light profile). On
REM Windows there is no pinned artifact: the agent installs (winget/pip). Honors the profile.
cls
call "%ALUY%" bootstrap --agent
REM clear before the session (each step starts clean, no accumulated noise).
cls
call "%ALUY%"
endlocal
