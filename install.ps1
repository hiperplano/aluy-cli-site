# ─────────────────────────────────────────────────────────────────────────────
# aluy — bootstrap (Windows / PowerShell).  irm https://aluy.dev/install.ps1 | iex
#
# Minimal by design: this script only ensures Node exists and installs the package
# (you can't run a Node program before Node exists). Everything else — splash,
# language, backend, provider, key, model, sidecars — is `aluy onboard` (Node +
# Ink): encoding-safe, i18n, one codebase. onboard is launched re-attached to the
# real console (not to the stdin of `| iex`).
#
# The VISUAL mirrors the brand (amber #DDA13F, the same accent as the Λluy splash):
# a bi-tone wordmark (Λ accent + "luy" depth) and amber numbered steps. Degrades
# clean: truecolor ANSI → named console colors → no color (NO_COLOR / redirected).
# Works on Windows PowerShell 5.1 AND PowerShell 7+.
#
# NOTE: all box-drawing/glyph characters are built from [char] code points so the
# source stays pure ASCII — this survives `irm | iex` regardless of how the host
# decodes the response (Windows PowerShell 5.1 does not assume UTF-8).
# ─────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$Pkg     = if ($env:ALUY_PKG) { $env:ALUY_PKG } else { '@hiperplano/aluy-cli' }
# SPEC = o que vai no `npm install`. O `@latest` só entra no DEFAULT: se alguém fixou
# ALUY_PKG para testar uma versão específica, grudar `@latest` sobrescreveria a escolha.
# `npm i -g pkg` já significa `pkg@latest` — escrever explícito deixa a intenção no
# comando (conferido no registro: o dist-tag `latest` aponta para a rc mais nova, então
# NÃO é o registro que entrega versão antiga).
$Spec    = if ($env:ALUY_PKG) { $env:ALUY_PKG } else { "${Pkg}@latest" }
$MinNode = 20

# ── Brand palette + VT detection ─────────────────────────────────────────────
# Truecolor ANSI when output is a real terminal the user didn't opt out of
# (NO_COLOR) and VT can be enabled. On Windows PowerShell 5.1 / legacy conhost VT
# is off by default, so we enable ENABLE_VIRTUAL_TERMINAL_PROCESSING via the Win32
# console API (a harmless no-op where it's already on: Windows Terminal, PS 7+).
$esc     = [char]27
$UseAnsi = $false
if (-not $env:NO_COLOR) {
  $redirected = $false
  try { $redirected = [Console]::IsOutputRedirected } catch {}
  if (-not $redirected) {
    try {
      Add-Type -Namespace Aluy -Name Vt -ErrorAction Stop -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true)]
public static extern System.IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, uint dwMode);
'@
      $h = [Aluy.Vt]::GetStdHandle(-11)          # STD_OUTPUT_HANDLE
      $mode = [uint32]0
      if ([Aluy.Vt]::GetConsoleMode($h, [ref]$mode)) {
        [void][Aluy.Vt]::SetConsoleMode($h, $mode -bor 0x0004)  # ENABLE_VIRTUAL_TERMINAL_PROCESSING
      }
      $UseAnsi = $true
    } catch {
      # Couldn't enable VT via the API — assume ANSI on PS 6+ (modern hosts render it).
      $UseAnsi = ($PSVersionTable.PSVersion.Major -ge 6)
    }
  }
}

if ($UseAnsi) {
  $AMBER = "$esc[38;2;221;161;63m"   # Λ   — --amber-400 #DDA13F (accent)
  $LUY   = "$esc[38;2;200;130;30m"   # luy — --amber-500 #C8821E (depth)
  $DIM   = "$esc[38;2;125;116;104m"  # secondary text (warm stone)
  $BOLD  = "$esc[1m"
  $RESET = "$esc[0m"
  $RED   = "$esc[38;2;207;83;83m"
  $OK    = "$esc[38;2;122;184;120m"
} else {
  $AMBER = ''; $LUY = ''; $DIM = ''; $BOLD = ''; $RESET = ''; $RED = ''; $OK = ''
}

# Glyphs (built from code points — see NOTE above).
$Blk  = [char]0x2588   # U+2588 FULL BLOCK
$Shd  = [char]0x2592   # U+2592 MEDIUM SHADE - a drop-shadow do wordmark do CLI
$GTri = [char]0x25B8   # ▸
$GOk  = [char]0x2713   # ✓
$GNo  = [char]0x2717   # ✗
$Dash = [char]0x2014   # —
$Mid  = [char]0x00B7   # ·

# ── UI helpers ───────────────────────────────────────────────────────────────
function Banner {
  # LOGO IDENTICO ao do CLI (`composeShadowedWordmark`, wordmark-3d.ts): a marca plana
  # daqui divergia da que o usuario ve ao rodar o aluy — duas caras para a mesma marca no
  # intervalo de um minuto (instalar, abrir).
  #
  # Montado por VARIAVEL, nunca com o caractere literal: o fonte precisa seguir ASCII puro
  # (ver NOTE no topo). Colar `##` e `##` direto no arquivo quebra o `irm | iex` quando o
  # host nao decodifica como UTF-8 — foi o que produziu os blocos corrompidos na tela do
  # Windows. Se o wordmark mudar no CLI, regerar aqui; a fonte da verdade e o componente.
  $b = $Blk
  $s = $Shd
  $L = @(
    "      $b$b       $b$b",
    "     $b$b$b$b      $b$b$s $b$b  $b$b  $b$b  $b$b",
    "   $b$b$b$s$s$b$b$b    $b$b$s $b$b$s $b$b$s $b$b$s $b$b$s",
    " $b$b$b$s$s$s  $s$b$b$b  $b$b$s $b$b$s $b$b$s  $b$b$b$b$b$s",
    "$b$b$b$s$s      $b$b$b $b$b$s  $b$b$b$b$b$s   $s$s$b$b$s",
    " $s$s$s        $s$s$s $s$s   $s$s$s$s$s  $b$b$b$b$s$s",
    "                             $s$s$s$s"
  )
  Write-Host ''
  # Uma cor só: no wordmark do CLI a sombra e a marca são o MESMO âmbar em intensidades
  # diferentes, e isso já está no desenho (`$b` cheio, `$s` meio-tom). Pintar as metades com
  # cores distintas, como o banner plano fazia, brigaria com a própria sombra.
  foreach ($ln in $L) {
    if ($UseAnsi) { Write-Host "  $AMBER$ln$RESET" }
    else { Write-Host "  $ln" -ForegroundColor DarkYellow }
  }
  Write-Host ''
  $tag = "terminal agent $Mid runs on your machine $Mid with your own LLM provider"
  if ($UseAnsi) { Write-Host "  $DIM$tag$RESET" } else { Write-Host "  $tag" -ForegroundColor DarkGray }
  Write-Host ''
}

function Say  ($m) { if ($UseAnsi) { Write-Host "  $AMBER$GTri$RESET $m" } else { Write-Host "  $GTri " -NoNewline -ForegroundColor Yellow; Write-Host $m } }
function Sub  ($m) { if ($UseAnsi) { Write-Host "    $DIM$m$RESET" } else { Write-Host "    $m" -ForegroundColor DarkGray } }
function Good ($m) { if ($UseAnsi) { Write-Host "  $OK$GOk$RESET $m" } else { Write-Host "  $GOk " -NoNewline -ForegroundColor Green; Write-Host $m } }
function Fail ($m) { if ($UseAnsi) { Write-Host "  $RED$GNo$RESET $m" } else { Write-Host "  $GNo " -NoNewline -ForegroundColor Red; Write-Host $m }; exit 1 }
function Step ($n, $m) {
  Write-Host ''
  if ($UseAnsi) { Write-Host "  $BOLD$AMBER$n$RESET  $m" }
  else { Write-Host "  $n" -NoNewline -ForegroundColor Yellow; Write-Host "  $m" }
}

Banner

# 1) Node >= 20 (the only prerequisite; installed via winget if missing)
Step '1/2' "Node $Dash aluy runs on it"
$nodeOk = $false
try { $v = (node -v) -replace '^v(\d+).*', '$1'; if ([int]$v -ge $MinNode) { $nodeOk = $true } } catch {}
if (-not $nodeOk) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Say 'Node not found - installing Node LTS via winget.'
    Sub 'the bar below is the Node download (may take a few minutes).'
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
  } else {
    Fail 'install Node >= 20 (https://nodejs.org) and run again.'
  }
} else {
  Good "Node $((node -v)) ready."
}

# 2) install (visible output). Explain WHAT the npm bar is downloading — otherwise
#    it just looks like a raw, opaque "node download" (owner's finding).
Step '2/2' 'downloading aluy and its components'
Sub '- terminal UI (Ink/React)   - secure credential access (keychain)'
Sub '- tool protocol (MCP)'
Sub 'the bar below is npm downloading these packages (some are native Node'
Sub 'binaries) - usually takes 1-2 min.'
# Onde o npm VAI escrever. No Windows o prefix global É o próprio diretório dos atalhos
# (%APPDATA%\npm) — não existe um `bin\` dentro dele; por isso o PATH recebe o prefix
# cru. Lido ANTES do install para depois resolver o binário pelo caminho ABSOLUTO, como
# o install.sh já faz com "$BIN/aluy".
$Prefix = $null
try { $Prefix = ("$(npm config get prefix 2>$null)").Trim() } catch {}
if (-not $Prefix) { $Prefix = $null }

# DEFEITO REAL (log do dono, no install.cmd — o mesmo buraco existia aqui): o
# `npm install` FALHOU e o script seguiu até anunciar "aluy installed". No Windows o npm
# não consegue apagar a instalação anterior (EPERM em arquivo travado) e aborta com
# EEXIST no atalho `%APPDATA%\npm\aluy`: a versão ANTIGA fica no lugar, o
# `Get-Command aluy` acha ELA, e o instalador declara sucesso abrindo a versão velha.
# Era assim que uma instalação "limpa" entregava um onboarding de outra versão.
#
# O `npm` fica em nível de SCRIPT de propósito — não dentro de função e sem captura de
# saída. Quem captura a saída de um comando nativo faz o PowerShell abrir um PIPE: o npm
# deixa de ver um console, some a barra de progresso, e (dentro de função) as linhas dele
# virariam o VALOR DE RETORNO. O veredito vem do `$LASTEXITCODE`, lido na linha seguinte.
#
# O `$ErrorActionPreference = 'Stop'` do topo é afrouxado em volta da chamada: no PS 5.1
# o stderr de um comando nativo pode virar erro TERMINANTE, e no PS 7.3+ com
# `$PSNativeCommandUseErrorActionPreference` um exit code != 0 vira EXCEÇÃO — dos dois
# jeitos o script morreria antes das mensagens abaixo, que são o ponto da correção.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$global:LASTEXITCODE = 0
npm install -g $Spec
$code = $LASTEXITCODE
$ErrorActionPreference = $prevEap
if ($code -ne 0) {
  Say 'npm failed - on Windows this is usually a locked previous install (EEXIST/EPERM).'
  Sub 'removing the leftovers of the previous install and trying once more.'
  # Remédio que o próprio npm sugere ao dar EEXIST: remover o que sobrou e instalar de
  # novo. Apagamos SÓ o que é nosso — os três atalhos `aluy*` e a pasta do pacote. Nunca
  # `--force`: aquilo manda o npm sobrescrever arquivo de qualquer dono, às cegas.
  if ($Prefix) {
    foreach ($f in @('aluy', 'aluy.cmd', 'aluy.ps1')) {
      Remove-Item -LiteralPath (Join-Path $Prefix $f) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath (Join-Path $Prefix 'node_modules\@hiperplano\aluy-cli') -Recurse -Force -ErrorAction SilentlyContinue
  }
  $ErrorActionPreference = 'Continue'
  $global:LASTEXITCODE = 0
  npm install -g $Spec
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prevEap
}
if ($code -ne 0) {
  Write-Host ''
  if ($UseAnsi) { Write-Host "  $RED$GNo$RESET npm could not install aluy - nothing was launched." }
  else { Write-Host "  $GNo " -NoNewline -ForegroundColor Red; Write-Host 'npm could not install aluy - nothing was launched.' }
  Sub '1. close every window running aluy or node - Windows locks those files'
  if ($Prefix) { Sub ('2. delete ' + (Join-Path $Prefix 'aluy') + ' and ' + (Join-Path $Prefix 'node_modules\@hiperplano')) }
  Sub "3. run again: npm install -g $Spec"
  exit 1
}

# PATH: prepend SEMPRE o prefix do npm. Antes isso só acontecia quando o `Get-Command
# aluy` FALHAVA — o inverso do necessário: havendo um `aluy` ANTIGO noutra pasta do PATH,
# o `Get-Command` acha ELE, o prefix novo nunca entra na frente, e a sessão abre na versão
# velha.
if ($Prefix) { $env:Path = "$Prefix;$env:Path" }

# Binário pelo caminho ABSOLUTO (paridade com o "$BIN/aluy" do install.sh): chamar `aluy`
# pelo nome entrega a decisão ao PATH, que é exatamente onde mora o defeito.
$Aluy = $null
if ($Prefix -and (Test-Path -LiteralPath (Join-Path $Prefix 'aluy.cmd'))) {
  $Aluy = Join-Path $Prefix 'aluy.cmd'
} else {
  $c = Get-Command aluy -ErrorAction SilentlyContinue
  if ($c) { $Aluy = $c.Source }
}
if (-not $Aluy) {
  Fail 'aluy is not on PATH - close and reopen the terminal, then run `aluy onboard`.'
}
Good 'aluy installed:'
# Mostra a versão RECÉM-instalada. É o jeito mais barato de o usuário ver, na hora, que
# não está abrindo uma instalação velha — foi exatamente o que passou despercebido.
& $Aluy --version

# Instalação ÓRFÃ sombreando a nova. No Windows é comum conviverem `%APPDATA%\npm` e um
# prefix próprio: a antiga vence o PATH em qualquer terminal novo e a pessoa roda a versão
# velha sem perceber, reportando defeito já corrigido. O install.sh avisa disso desde a
# correção #4; no Windows não havia equivalente. Comparamos a PASTA, não o arquivo: um
# mesmo diretório traz `aluy`, `aluy.cmd` e `aluy.ps1` e isso é UMA instalação só.
# Avisamos com o comando exato; não removemos nada por conta própria.
$others = @(Get-Command aluy -All -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Source } |
            Where-Object { $_ -and (Split-Path $_ -Parent) -ne (Split-Path $Aluy -Parent) })
if ($others.Count -gt 0) {
  Write-Host ''
  if ($UseAnsi) { Write-Host "  $RED$GNo$RESET there is ANOTHER aluy on your PATH:" }
  else { Write-Host "  $GNo " -NoNewline -ForegroundColor Red; Write-Host 'there is ANOTHER aluy on your PATH:' }
  foreach ($o in $others) { Sub $o }
  Sub "this install: $Aluy"
  Sub "the old one can shadow this one in other terminals - remove it with: npm rm -g $Pkg"
}

# O onboarding é Ink (React no terminal) e precisa de um CONSOLE de verdade. Com a saída
# redirecionada para arquivo, ou num terminal que não é console do Windows (Git
# Bash/MinTTY), `process.stdout.isTTY` é falso: o `aluy onboard` sai na hora dizendo que
# precisa de terminal interativo, o `aluy` sai com "sem objetivo e sem TTY", e a instalação
# termina SEM configurar nada — foi o que apareceu no log do dono. A checagem é a MESMA
# que o `runOnboard` faz (stdin E stdout), então não há falso positivo: se ela dispara, o
# onboard desistiria de qualquer jeito. Melhor dizer o que fazer.
$interactive = $true
try {
  if ([Console]::IsOutputRedirected -or [Console]::IsInputRedirected) { $interactive = $false }
} catch {}
if (-not $interactive) {
  Write-Host ''
  Say 'aluy is installed, but this terminal is not an interactive console.'
  Sub 'open Windows Terminal or PowerShell and run:  aluy onboard'
  exit 0
}

# 3) hand off to ONBOARD (Node/Ink). Under `irm | iex` the PowerShell pipeline
#    passes OBJECTS (not bytes on fd 0), so the process stdin stays the CONSOLE —
#    `aluy onboard` inherits the terminal and Ink reads the keyboard. Direct call
#    (NOT Start-Process: `aluy` is a `.cmd`/`.ps1` shim, not a Win32 `.exe`). Then
#    the session.
Clear-Host
& $Aluy onboard
# TURBO: provisions the sidecars via the agent (VISIBLE; a no-op for a light profile).
# On Windows there is no pinned artifact ⇒ the agent installs (winget/pip). `aluy
# bootstrap` honors the profile written by onboard. It must NEVER block the session:
# any provisioning error is tolerated — the final goal is ALWAYS to open `aluy`.
Clear-Host
$ErrorActionPreference = 'Continue'
try { & $Aluy bootstrap --agent } catch {
  if ($UseAnsi) { Write-Host "  $AMBER$GTri$RESET preparing the environment - continuing to the session." }
  else { Write-Host "  $GTri preparing the environment - continuing to the session." -ForegroundColor Yellow }
}
# clear before the session (each step starts clean, no accumulated noise).
Clear-Host
& $Aluy
