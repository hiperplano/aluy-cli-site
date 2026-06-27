#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# aluy — bootstrap (Linux / macOS).  curl -fsSL https://<host>/install.sh | bash
#
# MÍNIMO de propósito: a única coisa que precisa ser script é garantir o Node e
# instalar o pacote — porque você não pode rodar um programa Node antes do Node
# existir. Todo o resto (splash, idioma, backend, provider, chave, modelo,
# sidecars) é o `aluy onboard` (Node + Ink): encoding-safe, i18n, 1 código.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
PKG="${ALUY_PKG:-@hiperplano/aluy-cli}"
MIN_NODE=20

say() { printf '\033[36m▸\033[0m %s\n' "$*"; }
die() { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# 1) Node ≥ 20 (o único pré-requisito; instala via fnm/brew se faltar)
say "Passo 1/2 — verificando o Node (o aluy roda sobre ele)…"
node_major() { node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'; }
if ! command -v node >/dev/null 2>&1 || [ "$(node_major)" -lt "$MIN_NODE" ]; then
  say "  Node não encontrado — instalando (a barra abaixo é o download do Node)…"
  if   command -v fnm  >/dev/null 2>&1; then fnm install "$MIN_NODE" && fnm use "$MIN_NODE"
  elif command -v brew >/dev/null 2>&1; then brew install "node@${MIN_NODE}"
  else die "instale o Node ≥ ${MIN_NODE} (https://nodejs.org) e rode de novo."
  fi
else
  say "  Node $(node -v) ok."
fi

# 2) npm-global user-space (sem sudo)
PREFIX="$(npm config get prefix 2>/dev/null || echo '')"
if [ -z "$PREFIX" ] || [ ! -w "$PREFIX" ]; then
  PREFIX="$HOME/.aluy-npm"; mkdir -p "$PREFIX"; npm config set prefix "$PREFIX"
  export PATH="$PREFIX/bin:$PATH"
fi

# 3) instala. Explica O QUE a barra do npm baixa (senão parece "node" cru e opaco).
say "Passo 2/2 — baixando o aluy e seus componentes…"
say "  • interface de terminal (Ink/React)  • acesso seguro a credenciais (keychain)"
say "  • protocolo de ferramentas (MCP). A barra abaixo é o npm baixando esses pacotes"
say "  (alguns são binários nativos do Node) — costuma levar 1–2 min."
npm install -g "$PKG"
command -v aluy >/dev/null 2>&1 || die "aluy não ficou no PATH (verifique ${PREFIX}/bin)."

# 4) entrega pro ONBOARD (Node/Ink) reanexado ao TTY real (não ao stdin do pipe),
#    e depois entra na sessão. É aqui que a splash + idioma + setup acontecem.
if [ -r /dev/tty ]; then
  clear
  aluy onboard < /dev/tty || true
  # provisiona sidecars se profile=turbo (no-op se leve); no Linux baixa os artefatos pinados.
  clear
  aluy bootstrap < /dev/tty || true
  # tela limpa antes de abrir a sessão (cada etapa começa do zero, sem ruído acumulado).
  clear
  exec aluy < /dev/tty
else
  # sem TTY (CI/pipe sem terminal): instala e instrui (não trava).
  say 'instalado. rode:  aluy onboard'
fi
