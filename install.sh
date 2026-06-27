#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# aluy — bootstrap (Linux / macOS).  curl -fsSL https://aluy.dev/install.sh | bash
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

# 2) npm-global user-space (sem sudo). Se o prefix default não é gravável, usa
#    ~/.aluy-npm. SÓ a CRIAÇÃO do prefix fica no `if`; o PATH é tratado SEMPRE abaixo.
#    (Bug anterior: o `export PATH` vivia DENTRO do `if` → na 2ª instalação o prefix
#    já existia, o `if` era pulado, o PATH nunca era exportado → "aluy não ficou no
#    PATH". E nunca persistia no shell → sumia ao resetar o terminal.)
PREFIX="$(npm config get prefix 2>/dev/null || echo '')"
if [ -z "$PREFIX" ] || [ ! -w "$PREFIX" ]; then
  PREFIX="$HOME/.aluy-npm"; mkdir -p "$PREFIX"; npm config set prefix "$PREFIX"
fi
BIN="$PREFIX/bin"

# 2a) PATH no SHELL ATUAL (pro resto deste script achar o `aluy`)…
case ":$PATH:" in *":$BIN:"*) ;; *) export PATH="$BIN:$PATH";; esac
# 2b) …E PERSISTIDO (sobrevive ao reset do terminal). Idempotente, nos rc files que existem.
PERSIST="export PATH=\"$BIN:\$PATH\""
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  [ -e "$RC" ] || continue
  grep -qF "$BIN" "$RC" 2>/dev/null || printf '\n# aluy CLI (PATH)\n%s\n' "$PERSIST" >> "$RC"
done
# garante ao menos ~/.profile (sessões de login) se NENHUM rc file existia
[ -e "$HOME/.bashrc" ] || [ -e "$HOME/.zshrc" ] || [ -e "$HOME/.bash_profile" ] || [ -e "$HOME/.profile" ] || {
  printf '\n# aluy CLI (PATH)\n%s\n' "$PERSIST" >> "$HOME/.profile"
}

# 3) instala. Explica O QUE a barra do npm baixa (senão parece "node" cru e opaco).
say "Passo 2/2 — baixando o aluy e seus componentes…"
say "  • interface de terminal (Ink/React)  • acesso seguro a credenciais (keychain)"
say "  • protocolo de ferramentas (MCP). A barra abaixo é o npm baixando esses pacotes"
say "  (alguns são binários nativos do Node) — costuma levar 1–2 min."
npm install -g "$PKG"

# Resolve o binário pelo caminho ABSOLUTO (não depende do PATH já estar "quente").
ALUY="$BIN/aluy"
[ -x "$ALUY" ] || ALUY="$(command -v aluy 2>/dev/null || true)"
[ -n "$ALUY" ] && [ -x "$ALUY" ] || die "aluy instalou mas não achei o binário em ${BIN} (rode: ls ${BIN})."

# 4) entrega pro ONBOARD (Node/Ink) reanexado ao TTY real (não ao stdin do pipe), e
#    depois entra na sessão. Usa o caminho ABSOLUTO ($ALUY) p/ não depender do PATH.
if [ -r /dev/tty ]; then
  clear
  "$ALUY" onboard < /dev/tty || true
  clear
  "$ALUY" bootstrap < /dev/tty || true
  clear
  say "pronto. Numa NOVA aba/terminal o comando \`aluy\` já estará no PATH (ou rode: source ~/.bashrc)."
  exec "$ALUY" < /dev/tty
else
  say "instalado. abra um NOVO terminal (ou: source ~/.bashrc) e rode:  aluy onboard"
fi
