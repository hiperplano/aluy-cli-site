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
$Blk  = [char]0x2588   # █
$GTri = [char]0x25B8   # ▸
$GOk  = [char]0x2713   # ✓
$GNo  = [char]0x2717   # ✗
$Dash = [char]0x2014   # —
$Mid  = [char]0x00B7   # ·

# ── UI helpers ───────────────────────────────────────────────────────────────
function Banner {
  $f = $Blk
  $L = @(
    "      $f$f      ",
    "     $f$f$f$f     ",
    "   $f$f$f  $f$f$f   ",
    " $f$f$f      $f$f$f ",
    "$f$f$f        $f$f$f",
    "              ",
    "              "
  )
  $R = @(
    "$f$f                ",
    "$f$f  $f$f  $f$f  $f$f  $f$f",
    "$f$f  $f$f  $f$f  $f$f  $f$f",
    "$f$f  $f$f  $f$f   $f$f$f$f$f",
    "$f$f   $f$f$f$f$f      $f$f",
    "                $f$f",
    "            $f$f$f$f$f "
  )
  Write-Host ''
  for ($i = 0; $i -lt 7; $i++) {
    if ($UseAnsi) {
      Write-Host "  $AMBER$($L[$i])$RESET $LUY$($R[$i])$RESET"
    } else {
      Write-Host '  ' -NoNewline
      Write-Host $L[$i] -NoNewline -ForegroundColor Yellow
      Write-Host ' ' -NoNewline
      Write-Host $R[$i] -ForegroundColor DarkYellow
    }
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
npm install -g $Pkg
if (-not (Get-Command aluy -ErrorAction SilentlyContinue)) {
  $b = (npm config get prefix 2>$null); if ($b) { $env:Path = "$b;$env:Path" }
}
if (-not (Get-Command aluy -ErrorAction SilentlyContinue)) {
  Fail 'aluy is not on PATH - close and reopen the terminal, then run `aluy onboard`.'
}
Good 'aluy installed.'

# 3) hand off to ONBOARD (Node/Ink). Under `irm | iex` the PowerShell pipeline
#    passes OBJECTS (not bytes on fd 0), so the process stdin stays the CONSOLE —
#    `aluy onboard` inherits the terminal and Ink reads the keyboard. Direct call
#    (NOT Start-Process: `aluy` is a `.cmd`/`.ps1` shim, not a Win32 `.exe`). Then
#    the session.
Clear-Host
aluy onboard
# TURBO: provisions the sidecars via the agent (VISIBLE; a no-op for a light profile).
# On Windows there is no pinned artifact ⇒ the agent installs (winget/pip). `aluy
# bootstrap` honors the profile written by onboard. It must NEVER block the session:
# any provisioning error is tolerated — the final goal is ALWAYS to open `aluy`.
Clear-Host
$ErrorActionPreference = 'Continue'
try { aluy bootstrap --agent } catch {
  if ($UseAnsi) { Write-Host "  $AMBER$GTri$RESET preparing the environment - continuing to the session." }
  else { Write-Host "  $GTri preparing the environment - continuing to the session." -ForegroundColor Yellow }
}
# clear before the session (each step starts clean, no accumulated noise).
Clear-Host
aluy
