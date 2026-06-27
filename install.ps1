# ─────────────────────────────────────────────────────────────────────────────
# aluy — bootstrap (Windows / PowerShell).  irm https://<host>/install.ps1 | iex
#
# MÍNIMO de propósito: só garante o Node e instala o pacote (você não pode rodar um
# programa Node antes do Node existir). Todo o resto — splash, idioma, backend,
# provider, chave, modelo, sidecars — é o `aluy onboard` (Node + Ink): encoding-safe,
# i18n, 1 código. O onboard é lançado reanexado ao CONSOLE real (não ao stdin do `| iex`).
# ─────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$Pkg     = if ($env:ALUY_PKG) { $env:ALUY_PKG } else { '@hiperplano/aluy-cli' }
$MinNode = 20
function Say($m) { Write-Host "▸ $m" -ForegroundColor Cyan }

# 1) Node >= 20 (único pré-requisito)
Say 'Passo 1/2 — verificando o Node (o aluy roda sobre ele)…'
$nodeOk = $false
try { $v = (node -v) -replace '^v(\d+).*', '$1'; if ([int]$v -ge $MinNode) { $nodeOk = $true } } catch {}
if (-not $nodeOk) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Say '  Node não encontrado — baixando o Node LTS via winget. A barra abaixo é o'
    Say '  download do Node (pode levar alguns minutos).'
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
  } else {
    throw 'instale o Node >= 20 (https://nodejs.org) e rode de novo.'
  }
} else {
  Say "  Node $((node -v)) ok."
}

# 2) instala (saída visível). Explica O QUE a barra do npm está baixando — senão
#    parece um "download de node" cru e opaco (achado do dono).
Say 'Passo 2/2 — baixando o aluy e seus componentes…'
Say '  • interface de terminal (Ink/React)  • acesso seguro a credenciais (keychain)'
Say '  • protocolo de ferramentas (MCP). A barra abaixo é o npm baixando esses pacotes'
Say '  (alguns são binários nativos do Node) — costuma levar 1–2 min.'
npm install -g $Pkg
if (-not (Get-Command aluy -ErrorAction SilentlyContinue)) {
  $b = (npm config get prefix 2>$null); if ($b) { $env:Path = "$b;$env:Path" }
}
if (-not (Get-Command aluy -ErrorAction SilentlyContinue)) {
  throw 'aluy não ficou no PATH — feche e reabra o terminal e rode `aluy onboard`.'
}

# 3) entrega pro ONBOARD (Node/Ink). Em `irm | iex` o pipeline do PowerShell passa
#    OBJETOS (não bytes no fd 0), então o stdin do processo segue sendo o CONSOLE — o
#    `aluy onboard` herda o terminal e o Ink lê o teclado. Chamada DIRETA (NÃO
#    Start-Process: o `aluy` é um shim `.cmd`/`.ps1`, não um `.exe` Win32). Depois, a sessão.
# tela limpa antes do onboard (sai do ruído do npm install).
Clear-Host
aluy onboard
# TURBO: provisiona os sidecars via o agente (VISÍVEL; no-op se o perfil for leve). No
# Windows não há artefato pinado ⇒ o agente instala (winget/pip). Escolher turbo = consentir
# o --agent (⚠ --yolo). O `aluy bootstrap` respeita o perfil gravado pelo onboard.
Clear-Host
# O bootstrap NÃO pode impedir a sessão: qualquer erro/stderr do provisionamento é
# tolerado (volta pra 'Continue' e engole exceção) — o objetivo final é SEMPRE abrir o `aluy`.
$ErrorActionPreference = 'Continue'
try { aluy bootstrap --agent } catch { Write-Host '▸ preparando o ambiente — seguindo pra sessão.' -ForegroundColor Yellow }
# tela limpa antes de abrir a sessão (cada etapa começa do zero, sem ruído acumulado).
Clear-Host
aluy
