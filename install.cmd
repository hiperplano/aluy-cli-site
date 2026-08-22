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

REM -- LANGUAGE ------------------------------------------------------------------
REM Toda mensagem do instalador (inclusive termos e erros) sai de uma variavel
REM MSG_* daqui pra baixo, preenchida pela sub-rotina :msgs_en ou :msgs_pt la no
REM fim do arquivo. Batch nao tem hashtable nem funcao de verdade; uma variavel
REM por mensagem, chamada por `call :label`, e mais legivel que goto espalhado
REM pelo meio das mensagens.
REM
REM `chcp` NAO serve pra detectar idioma (e codepage do console, nao idioma do
REM Windows). Usamos o PowerShell, que existe em todo Windows suportado, so pra
REM ler a cultura configurada - `2^>nul` e o `if /i not ...` cobrem tanto a
REM ausencia do PowerShell quanto qualquer saida inesperada: sem pt CONFIRMADO,
REM cai em en. (Medido: sem locale configurada o .NET devolve a cultura
REM "invariant", nao "en" - por isso o fallback compara contra "pt", nunca
REM assume que "nao-vazio" significa "en" valido.)
set "LANG_DEFAULT=en"
for /f "delims=" %%L in ('powershell -NoProfile -Command "(Get-Culture).TwoLetterISOLanguageName" 2^>nul') do set "LANG_DEFAULT=%%L"
if /i not "%LANG_DEFAULT%"=="pt" set "LANG_DEFAULT=en"

set "LANG=%LANG_DEFAULT%"
echo(
echo   %TRI% idioma / language?  [1] Portugues  [2] English  ^(enter = %LANG_DEFAULT%^)
set "LANG_TRIES=0"

:lang_ask
set /a LANG_TRIES+=1
REM Mesmo teto de tentativas do bloco de termos, e pelo mesmo motivo real: um
REM console sem ninguem do outro lado devolve VAZIO pra sempre no `set /p` (nao
REM da erro) - sem este teto o instalador giraria em laco infinito so por causa
REM do idioma. Diferente dos termos: aqui ENTER vazio e ACEITE do detectado, nao
REM motivo pra perguntar de novo - so resposta com LIXO reincide.
if %LANG_TRIES% GTR 5 goto :lang_done
set "LANG_ANS="
set /p "LANG_ANS=  [enter/1/2]: "
if not defined LANG_ANS goto :lang_done
if "%LANG_ANS%"=="1"      goto :lang_pt
if /i "%LANG_ANS%"=="pt"  goto :lang_pt
if "%LANG_ANS%"=="2"      goto :lang_en
if /i "%LANG_ANS%"=="en"  goto :lang_en
goto :lang_ask

:lang_pt
set "LANG=pt"
goto :lang_done

:lang_en
set "LANG=en"
goto :lang_done

:lang_done
REM Catalogo de mensagens no idioma escolhido. :msgs_en roda SEMPRE primeiro (
REM garante que TODA chave tem um valor mesmo se algum dia :msgs_pt esquecer uma);
REM :msgs_pt, quando roda, so sobrescreve.
call :msgs_en
if /i "%LANG%"=="pt" call :msgs_pt

REM URL dos termos muda com o idioma (o site publica os dois); a mensagem em si
REM e a mesma variavel MSG_TERMS_HEADER pros dois casos, so a URL muda.
set "TERMS_URL=https://aluy.dev/termos.html"
if /i "%LANG%"=="pt" set "TERMS_URL=https://aluy.dev/pt/termos.html"

REM Propaga a escolha pro CLI: onboard/bootstrap (Node/Ink, i18n proprio) abrem
REM no MESMO idioma que o instalador usou. `pt-BR` e o codigo que o aluy espera
REM pra portugues; `en` cobre o resto.
set "ALUY_LANG=en"
if /i "%LANG%"=="pt" set "ALUY_LANG=pt-BR"

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
  echo   %DIM%%MSG_BANNER_TAG%%RESET%
) else (
  echo   Aluy
)
echo(

REM -- TERMS OF USE --------------------------------------------------------------
REM Consent comes BEFORE any download - including step 1, which may install Node
REM via winget. "Before downloading the components" means before the first byte.
if "%ALUY_ACCEPT_TERMS%"=="1" (
  echo       %DIM%%MSG_TERMS_ACCEPTED_ENV% %TERMS_URL%%RESET%
  goto :terms_ok
)
echo(
echo   %TRI% %MSG_TERMS_HEADER% %TERMS_URL%
echo       %DIM%%MSG_TERMS_B1%%RESET%
echo       %DIM%%MSG_TERMS_B2%%RESET%
echo       %DIM%%MSG_TERMS_B3%%RESET%
echo       %DIM%%MSG_TERMS_B4%%RESET%
echo(
set "TERMS_TRIES=0"

:terms_ask
set /a TERMS_TRIES+=1
REM Teto de tentativas: um console sem ninguem do outro lado devolve VAZIO para
REM sempre no `set /p` (nao da erro) - sem este teto o instalador giraria em laco
REM infinito. Cinco silencios nao e uma pessoa digitando; e uma maquina.
if %TERMS_TRIES% GTR 5 goto :terms_noanswer
set "TERMS_ANS="
set /p "TERMS_ANS=%MSG_TERMS_PROMPT%"
if not defined TERMS_ANS goto :terms_ask
if /i "%TERMS_ANS%"=="y"    goto :terms_ok
if /i "%TERMS_ANS%"=="yes"  goto :terms_ok
if /i "%TERMS_ANS%"=="s"    goto :terms_ok
if /i "%TERMS_ANS%"=="sim"  goto :terms_ok
if /i "%TERMS_ANS%"=="r"    goto :terms_read
if /i "%TERMS_ANS%"=="read" goto :terms_read
if /i "%TERMS_ANS%"=="l"    goto :terms_read
if /i "%TERMS_ANS%"=="ler"  goto :terms_read
if /i "%TERMS_ANS%"=="n"    goto :terms_no
if /i "%TERMS_ANS%"=="no"   goto :terms_no
if /i "%TERMS_ANS%"=="nao"  goto :terms_no
echo       %DIM%%MSG_TERMS_BAD_ANSWER%%RESET%
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
echo       %DIM%%MSG_TERMS_DECLINED%%RESET%
exit /b 1

:terms_noanswer
echo       %DIM%%MSG_TERMS_NO_ANSWER%%RESET%

:terms_ok
echo(
REM 1) Node (only prerequisite)
echo(
echo   %BOLD%%AMBER%1/2%RESET%  %MSG_STEP1%
where node >nul 2>nul
if not errorlevel 1 goto :node_found
where winget >nul 2>nul
if errorlevel 1 (
  echo   %CR% %MSG_NODE_MISSING%
  exit /b 1
)
echo   %TRI% %MSG_NODE_INSTALLING%
echo       %DIM%%MSG_NODE_BAR%%RESET%
winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
REM O winget instala o Node mas NAO atualiza o PATH DESTA sessao. Sem isto, o
REM `npm install` la embaixo morria com "'npm' nao e reconhecido" - e o script SEGUIA
REM adiante, terminando com uma mensagem de sucesso sem ter instalado nada. O
REM install.ps1 ja recarregava o PATH depois do winget; aqui nao havia equivalente.
set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"
where node >nul 2>nul
if not errorlevel 1 goto :node_found
echo   %CR% %MSG_NODE_NOT_VISIBLE%
echo       %DIM%%MSG_NODE_REOPEN%%RESET%
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
  echo   %CR% Node %NODEMAJOR% %MSG_NODE_TOO_OLD%
  exit /b 1
)
:node_ok

REM 2) install. Explain WHAT the npm bar is downloading (else it looks opaque).
echo(
echo   %BOLD%%AMBER%2/2%RESET%  %MSG_STEP2%
echo       %DIM%%MSG_STEP2_SUB1%%RESET%
echo       %DIM%%MSG_STEP2_SUB2%%RESET%
echo       %DIM%%MSG_STEP2_SUB3%%RESET%
echo       %DIM%%MSG_STEP2_SUB4%%RESET%
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
echo   %TRI% %MSG_NPM_FAILED%
echo       %DIM%%MSG_NPM_REMOVING%%RESET%
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
echo   %CR% %MSG_NPM_FAIL_FINAL%
echo       %DIM%%MSG_NPM_FAIL_1%%RESET%
echo       %DIM%%MSG_NPM_FAIL_2A% "%NPMPREFIX%\aluy" %MSG_NPM_FAIL_2B% "%NPMPREFIX%\node_modules\@hiperplano"%RESET%
echo       %DIM%%MSG_NPM_FAIL_3% %SPEC%%RESET%
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
echo   %CR% %MSG_ALUY_NOT_ON_PATH%
exit /b 1

:aluy_found
echo   %CK% %MSG_ALUY_INSTALLED%
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
echo   %CR% %MSG_SHADOW_HEADER%
for /f "delims=" %%A in ('where aluy 2^>nul') do if /i not "%%~dpA"=="%OURDIR%" echo       %%A
echo       %DIM%%MSG_SHADOW_THIS% %ALUY%%RESET%
echo       %DIM%%MSG_SHADOW_REMOVE% %PKG%%RESET%
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
echo   %TRI% %MSG_NOT_INTERACTIVE%
echo       %DIM%%MSG_NOT_INTERACTIVE_HINT%%RESET%
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
exit /b 0

REM ===========================================================================
REM  MESSAGE CATALOG - chamado por `call :msgs_en` / `call :msgs_pt` la em cima.
REM  Fica no fim do arquivo (idioma como sub-rotina, nao como bloco no meio do
REM  fluxo principal) porque o `exit /b 0` logo acima impede a execucao normal
REM  de "cair" aqui dentro - so entra via `call`, que sabe voltar sozinho no
REM  `goto :eof` de cada bloco.
REM
REM  SEM ACENTO no catalogo pt: o cmd.exe roda em code page 850/437 por padrao e
REM  acento vira lixo (o `chcp 65001` la em cima ajuda, mas nao em toda maquina/
REM  fonte/redirecionamento - e um requisito duro, nao uma preferencia estetica).
REM ===========================================================================

:msgs_en
set "MSG_BANNER_TAG=terminal agent · runs on your machine · with your own LLM provider"
set "MSG_TERMS_ACCEPTED_ENV=terms accepted via ALUY_ACCEPT_TERMS=1 -"
set "MSG_TERMS_HEADER=Terms of Use -"
set "MSG_TERMS_B1=* BETA software, provided AS-IS, WITHOUT warranty"
set "MSG_TERMS_B2=* runs on YOUR machine, under your responsibility"
set "MSG_TERMS_B3=* you use YOUR OWN provider credentials (BYO); they never pass through us"
set "MSG_TERMS_B4=* free to use, including commercially; open-source, no charge"
set "MSG_TERMS_PROMPT=  accept the terms? [y] yes / [r] read in full / [n] no: "
set "MSG_TERMS_BAD_ANSWER=answer y, r or n."
set "MSG_TERMS_DECLINED=installation cancelled - nothing was downloaded."
set "MSG_TERMS_NO_ANSWER=no answer received - proceeding implies ACCEPTING the terms above."
set "MSG_STEP1=Node - aluy runs on it"
set "MSG_NODE_MISSING=Node.js not found. Install Node 20+ (https://nodejs.org) and run again."
set "MSG_NODE_INSTALLING=Node not found - installing Node LTS via winget."
set "MSG_NODE_BAR=the bar below is the Node download (may take a few minutes)."
set "MSG_NODE_NOT_VISIBLE=Node was installed but is not visible in this session."
set "MSG_NODE_REOPEN=close this terminal, open a new one, and run the installer again."
set "MSG_NODE_TOO_OLD=is too old - aluy needs Node 20+. See https://nodejs.org"
set "MSG_STEP2=downloading aluy and its components"
set "MSG_STEP2_SUB1=- terminal UI (Ink/React)   - secure credential access (keychain)"
set "MSG_STEP2_SUB2=- tool protocol (MCP)"
set "MSG_STEP2_SUB3=the bar below is npm downloading these packages (some are native Node"
set "MSG_STEP2_SUB4=binaries) - usually takes 1-2 min."
set "MSG_NPM_FAILED=npm failed - on Windows this is usually a locked previous install: EEXIST/EPERM."
set "MSG_NPM_REMOVING=removing the leftovers of the previous install and trying once more."
set "MSG_NPM_FAIL_FINAL=npm could not install aluy - nothing was launched."
set "MSG_NPM_FAIL_1=1. close every window running aluy or node - Windows locks those files"
set "MSG_NPM_FAIL_2A=2. delete"
set "MSG_NPM_FAIL_2B=and"
set "MSG_NPM_FAIL_3=3. run again: npm install -g"
set "MSG_ALUY_NOT_ON_PATH=aluy is not on PATH. Close and reopen the terminal, then run: aluy onboard"
set "MSG_ALUY_INSTALLED=aluy installed:"
set "MSG_SHADOW_HEADER=there is ANOTHER aluy on your PATH:"
set "MSG_SHADOW_THIS=this install:"
set "MSG_SHADOW_REMOVE=the old one can shadow this one in other terminals - remove it with: npm rm -g"
set "MSG_NOT_INTERACTIVE=aluy is installed, but this terminal is not an interactive console."
set "MSG_NOT_INTERACTIVE_HINT=open Command Prompt or Windows Terminal and run:  aluy onboard"
goto :eof

:msgs_pt
set "MSG_BANNER_TAG=agente de terminal · roda na sua maquina · com o seu provider de LLM"
set "MSG_TERMS_ACCEPTED_ENV=termos aceitos via ALUY_ACCEPT_TERMS=1 -"
set "MSG_TERMS_HEADER=Termos de Uso -"
set "MSG_TERMS_B1=* software em BETA, fornecido AS-IS, SEM garantia"
set "MSG_TERMS_B2=* roda na SUA maquina, sob sua responsabilidade"
set "MSG_TERMS_B3=* voce usa suas PROPRIAS credenciais de provider (BYO); elas nunca passam por nos"
set "MSG_TERMS_B4=* uso livre, inclusive comercial; open-source, sem cobranca"
set "MSG_TERMS_PROMPT=  aceita os termos? [s] sim / [l] ler na integra / [n] nao: "
set "MSG_TERMS_BAD_ANSWER=responda s, l ou n."
set "MSG_TERMS_DECLINED=instalacao cancelada - nada foi baixado."
set "MSG_TERMS_NO_ANSWER=nenhuma resposta recebida - prosseguir implica ACEITAR os termos acima."
set "MSG_STEP1=Node - o aluy roda sobre ele"
set "MSG_NODE_MISSING=Node.js nao encontrado. Instale o Node 20+ (https://nodejs.org) e rode novamente."
set "MSG_NODE_INSTALLING=Node nao encontrado - instalando Node LTS via winget."
set "MSG_NODE_BAR=a barra abaixo e o download do Node (pode levar alguns minutos)."
set "MSG_NODE_NOT_VISIBLE=Node foi instalado mas nao esta visivel nesta sessao."
set "MSG_NODE_REOPEN=feche este terminal, abra um novo, e rode o instalador novamente."
set "MSG_NODE_TOO_OLD=e muito antigo - aluy precisa do Node 20+. Veja https://nodejs.org"
set "MSG_STEP2=baixando o aluy e seus componentes"
set "MSG_STEP2_SUB1=- interface de terminal (Ink/React)   - acesso seguro a credenciais (keychain)"
set "MSG_STEP2_SUB2=- protocolo de ferramentas (MCP)"
set "MSG_STEP2_SUB3=a barra abaixo e o npm baixando esses pacotes (alguns sao binarios nativos"
set "MSG_STEP2_SUB4=do Node) - costuma levar 1-2 min."
set "MSG_NPM_FAILED=npm falhou - no Windows isso costuma ser uma instalacao anterior travada: EEXIST/EPERM."
set "MSG_NPM_REMOVING=removendo os restos da instalacao anterior e tentando mais uma vez."
set "MSG_NPM_FAIL_FINAL=npm nao conseguiu instalar o aluy - nada foi aberto."
set "MSG_NPM_FAIL_1=1. feche toda janela rodando aluy ou node - o Windows trava esses arquivos"
set "MSG_NPM_FAIL_2A=2. apague"
set "MSG_NPM_FAIL_2B=e"
set "MSG_NPM_FAIL_3=3. rode novamente: npm install -g"
set "MSG_ALUY_NOT_ON_PATH=aluy nao esta no PATH. Feche e reabra o terminal, depois rode: aluy onboard"
set "MSG_ALUY_INSTALLED=aluy instalado:"
set "MSG_SHADOW_HEADER=existe OUTRO aluy no seu PATH:"
set "MSG_SHADOW_THIS=esta instalacao:"
set "MSG_SHADOW_REMOVE=a antiga pode encobrir esta em outros terminais - remova com: npm rm -g"
set "MSG_NOT_INTERACTIVE=aluy esta instalado, mas este terminal nao e um console interativo."
set "MSG_NOT_INTERACTIVE_HINT=abra o Prompt de Comando ou Windows Terminal e rode:  aluy onboard"
goto :eof

endlocal
