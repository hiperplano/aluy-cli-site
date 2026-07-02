#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# aluy — bootstrap (Linux / macOS).  curl -fsSL https://aluy.dev/install.sh | bash
#
# MÍNIMO de propósito: a única coisa que precisa ser script é garantir o Node e
# instalar o pacote — porque você não pode rodar um programa Node antes do Node
# existir. Todo o resto (splash, idioma, backend, provider, chave, modelo,
# sidecars) é o `aluy onboard` (Node + Ink): encoding-safe, i18n, 1 código.
#
# O VISUAL segue a marca (âmbar #DDA13F, o mesmo accent do splashscreen Λluy):
# wordmark bi-tom (Λ accent + "luy" depth), passos numerados âmbar. Degrada
# limpo: truecolor → 256-cor → sem-cor (NO_COLOR / saída não-TTY / TERM=dumb).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
PKG="${ALUY_PKG:-@hiperplano/aluy-cli}"
MIN_NODE=20

# ── Cores da MARCA (espelham accent/depth do DS: --amber-400 #DDA13F / --amber-500
#    #C8821E). Só quando há TTY colorido E o usuário não pediu NO_COLOR. Truecolor
#    (24-bit) quando o terminal anuncia COLORTERM; senão 256-cor aproximada; senão nada.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
  if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
    AMBER=$'\033[38;2;221;161;63m'    # Λ  — --amber-400 #DDA13F (accent)
    LUY=$'\033[38;2;200;130;30m'      # luy — --amber-500 #C8821E (depth)
    DIM=$'\033[38;2;125;116;104m'     # texto secundário (stone morno)
  else
    AMBER=$'\033[38;5;179m'; LUY=$'\033[38;5;136m'; DIM=$'\033[38;5;244m'
  fi
  BOLD=$'\033[1m'; RESET=$'\033[0m'; RED=$'\033[38;5;203m'; OK=$'\033[38;5;114m'
else
  AMBER=''; LUY=''; DIM=''; BOLD=''; RESET=''; RED=''; OK=''
fi

# ── Wordmark "Λluy" bi-tom (block-art — a MESMA arte do <Wordmark>/splash: o Λ em
#    accent, "luy" em depth). Impresso uma vez, no topo, p/ dar cara de marca. ────
banner() {
  printf '\n'
  printf '  %s  ██   %s %s██                %s\n'  "$AMBER" "$RESET" "$LUY" "$RESET"
  printf '  %s ████  %s %s██  ██  ██  ██  ██%s\n'  "$AMBER" "$RESET" "$LUY" "$RESET"
  printf '  %s ██ ██ %s %s██  ██  ██  ██  ██%s\n'  "$AMBER" "$RESET" "$LUY" "$RESET"
  printf '  %s██   ██%s %s██  ██  ██   █████%s\n'  "$AMBER" "$RESET" "$LUY" "$RESET"
  printf '  %s██   ██%s %s██   █████      ██%s\n'  "$AMBER" "$RESET" "$LUY" "$RESET"
  printf '  %s       %s %s                ██%s\n'  "$AMBER" "$RESET" "$LUY" "$RESET"
  printf '\n'
  printf '  %sagente de terminal · roda na sua máquina · com o seu provider de LLM%s\n' "$DIM" "$RESET"
  printf '\n'
}

say()  { printf '  %s▸%s %s\n' "$AMBER" "$RESET" "$*"; }
sub()  { printf '    %s%s%s\n' "$DIM" "$*" "$RESET"; }
good() { printf '  %s✓%s %s\n' "$OK" "$RESET" "$*"; }
die()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
step() { printf '\n  %s%s%s  %s\n' "$BOLD$AMBER" "$1" "$RESET" "$2"; }

banner

# 1) Node ≥ 20 (o único pré-requisito; instala via fnm/brew se faltar)
step "1/2" "Node — o aluy roda sobre ele"
node_major() { node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'; }
if ! command -v node >/dev/null 2>&1 || [ "$(node_major)" -lt "$MIN_NODE" ]; then
  say "Node não encontrado — instalando (a barra abaixo é o download do Node)…"
  if   command -v fnm  >/dev/null 2>&1; then fnm install "$MIN_NODE" && fnm use "$MIN_NODE"
  elif command -v brew >/dev/null 2>&1; then brew install "node@${MIN_NODE}"
  else die "instale o Node ≥ ${MIN_NODE} (https://nodejs.org) e rode de novo."
  fi
else
  good "Node $(node -v) ok."
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
step "2/2" "baixando o aluy e seus componentes"
sub "• interface de terminal (Ink/React)   • acesso seguro a credenciais (keychain)"
sub "• protocolo de ferramentas (MCP)"
sub "a barra abaixo é o npm baixando esses pacotes (alguns são binários nativos"
sub "do Node) — costuma levar 1–2 min."
npm install -g "$PKG"

# Resolve o binário pelo caminho ABSOLUTO (não depende do PATH já estar "quente").
ALUY="$BIN/aluy"
[ -x "$ALUY" ] || ALUY="$(command -v aluy 2>/dev/null || true)"
[ -n "$ALUY" ] && [ -x "$ALUY" ] || die "aluy instalou mas não achei o binário em ${BIN} (rode: ls ${BIN})."

good "aluy instalado."

# 4) entrega pro ONBOARD (Node/Ink) reanexado ao TTY real (não ao stdin do pipe), e
#    depois entra na sessão. Usa o caminho ABSOLUTO ($ALUY) p/ não depender do PATH.
if [ -r /dev/tty ]; then
  clear
  "$ALUY" onboard < /dev/tty || true
  clear
  "$ALUY" bootstrap < /dev/tty || true
  clear
  good "pronto. Numa NOVA aba/terminal o comando \`aluy\` já estará no PATH (ou rode: source ~/.bashrc)."
  exec "$ALUY" < /dev/tty
else
  good "instalado. abra um NOVO terminal (ou: source ~/.bashrc) e rode:  aluy onboard"
fi
