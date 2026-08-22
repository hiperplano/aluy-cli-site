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
  # LOGO IDÊNTICO ao do CLI (`composeShadowedWordmark` do wordmark-3d.ts) — a marca
  # plana daqui divergia da que o usuário vê ao rodar o aluy: mesma silhueta, SEM a
  # drop-shadow `▒`. Duas caras para a mesma marca no mesmo minuto (instalar → abrir).
  # Se o wordmark mudar lá, regerar aqui — a fonte da verdade é o componente.
  printf '  %s      ██       ██%s\n' "$AMBER" "$RESET"
  printf '  %s     ████      ██▒ ██  ██  ██  ██%s\n' "$AMBER" "$RESET"
  printf '  %s   ███▒▒███    ██▒ ██▒ ██▒ ██▒ ██▒%s\n' "$AMBER" "$RESET"
  printf '  %s ███▒▒▒  ▒███  ██▒ ██▒ ██▒  █████▒%s\n' "$AMBER" "$RESET"
  printf '  %s███▒▒      ███ ██▒  █████▒   ▒▒██▒%s\n' "$AMBER" "$RESET"
  printf '  %s ▒▒▒        ▒▒▒ ▒▒   ▒▒▒▒▒  ████▒▒%s\n' "$AMBER" "$RESET"
  printf '  %s                             ▒▒▒▒%s\n' "$AMBER" "$RESET"
  printf '\n'
}

say()  { printf '  %s▸%s %s\n' "$AMBER" "$RESET" "$*"; }
sub()  { printf '    %s%s%s\n' "$DIM" "$*" "$RESET"; }
good() { printf '  %s✓%s %s\n' "$OK" "$RESET" "$*"; }
die()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
step() { printf '\n  %s%s%s  %s\n' "$BOLD$AMBER" "$1" "$RESET" "$2"; }

# ── IDIOMA ─────────────────────────────────────────────────────────────────────
# A escolha vem ANTES dos termos — de nada adianta oferecer a leitura dos termos
# num idioma que a pessoa não lê. Ela governa TODA mensagem daqui p/ baixo,
# inclusive as de erro, e é propagada ao CLI (`ALUY_LANG`) p/ o onboard já abrir
# no mesmo idioma em vez de perguntar de novo.
ALUY_UI_LANG=""

# Padrão = idioma do sistema. `LC_ALL` > `LC_MESSAGES` > `LANG` é a precedência do
# próprio POSIX; respeitá-la evita "detectar" pt numa conta configurada em inglês.
detect_lang() {
  case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
    pt*|PT*) printf 'pt' ;;
    *)       printf 'en' ;;
  esac
}

# Catálogo. Chave prefixada pelo idioma p/ as duas versões ficarem LADO A LADO —
# num arquivo com dois blocos separados, uma tradução esquecida some sem barulho.
t() {
  case "$ALUY_UI_LANG:$1" in
    pt:tagline)   printf 'agente de terminal · roda na sua máquina · com o seu provider de LLM' ;;
    en:tagline)   printf 'terminal agent · runs on your machine · with your own LLM provider' ;;
    pt:win)       printf 'este é o instalador de Linux/macOS — no Windows use o PowerShell:' ;;
    en:win)       printf 'this is the Linux/macOS installer — on Windows use PowerShell:' ;;
    pt:win2)      printf 'ou, se já tem Node ≥' ;;
    en:win2)      printf 'or, if you already have Node ≥' ;;
    pt:terms.t)   printf 'Termos de Uso' ;;
    en:terms.t)   printf 'Terms of Use' ;;
    pt:terms.1)   printf '• software em BETA, fornecido "como está", SEM garantia' ;;
    en:terms.1)   printf '• BETA software, provided "as is", WITHOUT warranty' ;;
    pt:terms.2)   printf '• roda na SUA máquina, sob sua responsabilidade' ;;
    en:terms.2)   printf '• runs on YOUR machine, under your responsibility' ;;
    pt:terms.3)   printf '• você usa as SUAS credenciais de provider (BYO); elas nunca passam por nós' ;;
    en:terms.3)   printf '• you use YOUR OWN provider credentials (BYO); they never pass through us' ;;
    pt:terms.4)   printf '• uso livre, inclusive corporativo; open-source, sem cobrança' ;;
    en:terms.4)   printf '• free to use, including commercially; open-source, no charge' ;;
    pt:terms.ask) printf 'aceita os termos? [s] sim · [l] ler na íntegra · [n] não: ' ;;
    en:terms.ask) printf 'accept the terms? [y] yes · [r] read in full · [n] no: ' ;;
    pt:terms.bad) printf 'responda s, l ou n.' ;;
    en:terms.bad) printf 'answer y, r or n.' ;;
    pt:terms.no)  printf 'instalação cancelada — nada foi baixado.' ;;
    en:terms.no)  printf 'installation cancelled — nothing was downloaded.' ;;
    pt:terms.ni)  printf 'instalação não interativa — prosseguir implica ACEITAR os termos acima.' ;;
    en:terms.ni)  printf 'non-interactive install — proceeding implies ACCEPTING the terms above.' ;;
    pt:terms.env) printf 'termos aceitos via ALUY_ACCEPT_TERMS=1 —' ;;
    en:terms.env) printf 'terms accepted via ALUY_ACCEPT_TERMS=1 —' ;;
    pt:terms.err) printf 'não consegui baixar os termos agora — leia em' ;;
    en:terms.err) printf 'could not fetch the terms right now — read them at' ;;
    pt:s1)        printf 'Node — o aluy roda sobre ele' ;;
    en:s1)        printf 'Node — aluy runs on it' ;;
    pt:s1.miss)   printf 'Node não encontrado — instalando (a barra abaixo é o download do Node)…' ;;
    en:s1.miss)   printf 'Node not found — installing (the bar below is the Node download)…' ;;
    pt:s1.ok)     printf 'ok.' ;;
    en:s1.ok)     printf 'ok.' ;;
    pt:s2)        printf 'baixando o aluy e seus componentes' ;;
    en:s2)        printf 'downloading aluy and its components' ;;
    pt:s2.a)      printf '• interface de terminal (Ink/React)   • acesso seguro a credenciais (keychain)' ;;
    en:s2.a)      printf '• terminal interface (Ink/React)   • secure credential access (keychain)' ;;
    pt:s2.b)      printf '• protocolo de ferramentas (MCP)' ;;
    en:s2.b)      printf '• tool protocol (MCP)' ;;
    pt:s2.c)      printf 'a barra abaixo é o npm baixando esses pacotes (alguns são binários nativos' ;;
    en:s2.c)      printf 'the bar below is npm fetching those packages (some are native Node' ;;
    pt:s2.d)      printf 'do Node) — costuma levar 1–2 min.' ;;
    en:s2.d)      printf 'binaries) — usually takes 1–2 min.' ;;
    pt:done)      printf 'aluy instalado.' ;;
    en:done)      printf 'aluy installed.' ;;
    pt:shadow)    printf 'a antiga pode SOMBREAR a nova em outros shells (você rodaria a versão velha).' ;;
    en:shadow)    printf 'the old one may SHADOW the new one in other shells (you would run the old version).' ;;
    pt:shadow2)   printf 'para remover a antiga (feita com sudo):  sudo npm rm -g' ;;
    en:shadow2)   printf 'to remove the old one (installed with sudo):  sudo npm rm -g' ;;
    pt:this)      printf 'esta instalação:' ;;
    en:this)      printf 'this install:' ;;
    pt:ready)     printf 'pronto. Numa NOVA aba/terminal o comando `aluy` já estará no PATH (ou rode: source ~/.bashrc).' ;;
    en:ready)     printf 'done. In a NEW tab/terminal the `aluy` command will be on PATH (or run: source ~/.bashrc).' ;;
    pt:ready2)    printf 'instalado. abra um NOVO terminal (ou: source ~/.bashrc) e rode:  aluy onboard' ;;
    en:ready2)    printf 'installed. open a NEW terminal (or: source ~/.bashrc) and run:  aluy onboard' ;;
    *)            printf '%s' "$1" ;;
  esac
}

# Pergunta o idioma. A pergunta é BILÍNGUE de propósito: ela vem ANTES da escolha,
# então não pode assumir nenhum dos dois.
choose_lang() {
  _def="$(detect_lang)"
  ALUY_UI_LANG="$_def"
  # Escotilha p/ automação e p/ quem quer forçar: ALUY_LANG=pt|en|pt-BR.
  case "${ALUY_LANG:-}" in
    pt*|PT*) ALUY_UI_LANG="pt"; return 0 ;;
    en*|EN*) ALUY_UI_LANG="en"; return 0 ;;
  esac
  # Sem terminal ⇒ fica o detectado, sem travar (mesma razão do aceite dos termos).
  (: < /dev/tty) 2>/dev/null || return 0
  printf '\n'
  printf '  %s▸%s idioma / language?  [1] Português  [2] English  (enter = %s)\n' "$AMBER" "$RESET" "$_def"
  printf '  %s▸%s > ' "$AMBER" "$RESET"
  read -r _l < /dev/tty || _l=""
  case "$_l" in
    1|pt|PT|Pt|br|BR) ALUY_UI_LANG="pt" ;;
    2|en|EN|En)       ALUY_UI_LANG="en" ;;
  esac
}

# ── TERMOS DE USO ──────────────────────────────────────────────────────────────
# O aceite vem ANTES de qualquer download — inclusive antes do passo 1, que pode
# instalar o Node. "Antes de baixar os componentes" significa antes do primeiro
# byte, não antes do `npm install`.
# A URL segue o IDIOMA escolhido — oferecer a leitura dos termos numa língua que a
# pessoa não lê é oferecer nada. Função, não variável: `choose_lang` roda DEPOIS
# deste ponto do arquivo, então um valor fixado aqui congelaria o idioma errado.
terms_url() {
  if [ "$ALUY_UI_LANG" = "pt" ]; then printf 'https://aluy.dev/pt/termos.html'
  else printf 'https://aluy.dev/termos.html'; fi
}

# Mostra os termos NO TERMINAL. Não abre navegador de propósito: quem instala por
# `curl | sh` costuma estar em SSH/servidor/WSL, onde não há navegador — e um
# comando que "abre" nada seria pior que não oferecer a leitura.
show_terms() {
  _t=""
  if   command -v curl >/dev/null 2>&1; then _t="$(curl -fsSL --max-time 15 "$(terms_url)" 2>/dev/null || true)"
  elif command -v wget >/dev/null 2>&1; then _t="$(wget -qO- --timeout=15 "$(terms_url)" 2>/dev/null || true)"
  fi
  if [ -z "$_t" ]; then
    printf '\n'; sub "$(t terms.err) $(terms_url)"; printf '\n'
    return 0
  fi
  # `<main>` delimita o conteúdo; sem isso o menu de navegação do site vem junto.
  printf '\n%s\n\n' "$(printf '%s' "$_t" \
    | sed -n '/<main>/,/<\/main>/p' \
    | sed -e 's/<script[^>]*>.*<\/script>//g' -e 's/<style[^>]*>.*<\/style>//g' -e 's/<[^>]*>//g' \
    | sed -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e "s/&#39;/'/g" -e 's/&quot;/"/g' -e 's/&nbsp;/ /g' \
    | sed -e 's/^[[:space:]]*//' -e '/^$/d')"
}

accept_terms() {
  # Escotilha para automação (CI, Dockerfile, provisionamento) e p/ quem já leu.
  if [ "${ALUY_ACCEPT_TERMS:-}" = "1" ]; then
    sub "$(t terms.env) $(terms_url)"
    return 0
  fi
  printf '\n'
  say "$(t terms.t) — $(terms_url)"
  sub "$(t terms.1)"
  sub "$(t terms.2)"
  sub "$(t terms.3)"
  sub "$(t terms.4)"
  printf '\n'
  # SEM terminal (curl | sh dentro de CI, container sem tty): não há quem responda.
  # Travar aqui quebraria o método de instalação DOCUMENTADO na home do site, então
  # seguimos — mas dizendo, sem rodeio, que prosseguir é aceitar.
  # `[ -r /dev/tty ]` NÃO serve: num container de CI o nó existe e é "legível", mas o
  # open falha com ENXIO — o teste passava, o `read` morria e o instalador CANCELAVA
  # (pego no teste desta função). A pergunta certa é "consigo ABRIR?", e ela se faz
  # tentando, num SUBSHELL: se a redireção falhar no shell corrente, `exec` derruba o
  # processo inteiro.
  if ! (: < /dev/tty) 2>/dev/null; then
    sub "$(t terms.ni)"
    printf '\n'
    return 0
  fi
  while :; do
    printf '  %s▸%s %s' "$AMBER" "$RESET" "$(t terms.ask)"
    read -r _ans < /dev/tty || _ans="n"
    case "$(printf '%s' "$_ans" | tr 'A-Z' 'a-z')" in
      s|sim|y|yes) printf '\n'; return 0 ;;
      l|ler|r)     show_terms ;;
      n|nao|no)    printf '\n'; sub "$(t terms.no)"; exit 1 ;;
      *)           sub "$(t terms.bad)" ;;
    esac
  done
}

banner
choose_lang
printf '  %s%s%s\n\n' "$DIM" "$(t tagline)" "$RESET"
# O CLI herda o idioma escolhido — sem isto o `aluy onboard` logo abaixo abriria
# noutro idioma e perguntaria de novo o que a pessoa acabou de responder.
ALUY_LANG="$( [ "$ALUY_UI_LANG" = "pt" ] && printf 'pt-BR' || printf 'en' )"
export ALUY_LANG
accept_terms

# 0) WINDOWS — este script é o de Unix. Sair CEDO e apontar o certo.
#
#    O que acontecia sem isto (relatado pelo dono, com Node v24 instalado e npm 11
#    funcionando): rodar `curl … install.sh | bash` no Windows caía no passo 1, o
#    `command -v node` falhava (num bash do Windows o executável é `node.exe`; e num
#    WSL o Node do Windows não está no PATH do Linux), o script anunciava "Node não
#    encontrado — instalando", procurava `fnm`/`brew` que não existem ali, e morria
#    mandando INSTALAR O QUE JÁ ESTAVA INSTALADO. A mensagem apontava para o lugar
#    errado e não havia como o usuário adivinhar que o problema era o instalador.
#
#    Detecta pelo `uname` (MINGW/MSYS/CYGWIN = bash do Windows) e por `WSL_DISTRO_NAME`
#    combinado com a AUSÊNCIA de `node` — no WSL puro o instalador Unix é o correto, e
#    só é o errado quando a pessoa quer o aluy do lado Windows.
_uname="$(uname -s 2>/dev/null || echo desconhecido)"
case "$_uname" in
  MINGW*|MSYS*|CYGWIN*)
    printf '\n  %s✗%s %s\n' "$RED" "$RESET" "$(t win)" >&2
    printf '\n      %sirm https://aluy.dev/install.ps1 | iex%s\n' "$BOLD" "$RESET" >&2
    printf '\n    ou, se já tem Node ≥ %s: %snpm i -g @hiperplano/aluy-cli%s\n\n' "$MIN_NODE" "$BOLD" "$RESET" >&2
    exit 1
    ;;
esac
if [ -n "${WSL_DISTRO_NAME:-}" ] && ! command -v node >/dev/null 2>&1; then
  printf '\n  %s✗%s você está no WSL (%s) e não há Node AQUI dentro.\n' "$RED" "$RESET" "$WSL_DISTRO_NAME" >&2
  printf '    O Node do Windows não vale para o WSL — são dois sistemas.\n' >&2
  printf '\n    Para o aluy no WSL:     %ssudo apt install nodejs%s (ou fnm/nvm) e rode de novo\n' "$BOLD" "$RESET" >&2
  printf '    Para o aluy no Windows: %sirm https://aluy.dev/install.ps1 | iex%s (no PowerShell)\n\n' "$BOLD" "$RESET" >&2
  exit 1
fi

# 1) Node ≥ 20 (o único pré-requisito; instala via fnm/brew se faltar)
step "1/2" "$(t s1)"
node_major() { node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'; }
if ! command -v node >/dev/null 2>&1 || [ "$(node_major)" -lt "$MIN_NODE" ]; then
  say "$(t s1.miss)"
  if   command -v fnm  >/dev/null 2>&1; then fnm install "$MIN_NODE" && fnm use "$MIN_NODE"
  elif command -v brew >/dev/null 2>&1; then brew install "node@${MIN_NODE}"
  else die "instale o Node ≥ ${MIN_NODE} (https://nodejs.org) e rode de novo."
  fi
else
  good "Node $(node -v) $(t s1.ok)"
fi

# 2) npm-global user-space (sem sudo). Se o prefix default não é gravável, usa
#    ~/.aluy-npm. SÓ a CRIAÇÃO do prefix fica no `if`; o PATH é tratado SEMPRE abaixo.
#    (Bug anterior: o `export PATH` vivia DENTRO do `if` → na 2ª instalação o prefix
#    já existia, o `if` era pulado, o PATH nunca era exportado → "aluy não ficou no
#    PATH". E nunca persistia no shell → sumia ao resetar o terminal.)
#
#    O TESTE é no ALVO REAL, não no prefix: o `npm i -g` escreve em
#    `$PREFIX/lib/node_modules` (e em `$PREFIX/bin`), não em `$PREFIX`. Um
#    `/usr/local` gravável com `lib/node_modules` do root passava no `-w "$PREFIX"`
#    e estourava EACCES no meio do download. Como o diretório pode ainda não existir,
#    subimos até o primeiro ancestral EXISTENTE e testamos nele.
npm_target_writable() {
  [ -n "${1:-}" ] || return 1
  for sub in lib/node_modules bin; do
    d="$1/$sub"
    while [ ! -e "$d" ] && [ "$d" != "/" ] && [ "$d" != "." ]; do d="$(dirname "$d")"; done
    [ -w "$d" ] || return 1
  done
  return 0
}

PREFIX="$(npm config get prefix 2>/dev/null || echo '')"
if ! npm_target_writable "$PREFIX"; then
  PREFIX="$HOME/.aluy-npm"; mkdir -p "$PREFIX"
  # `--location=user` é OBRIGATÓRIO aqui. Sem ele, no npm empacotado do Debian
  # (que traz `globalconfig=/etc/npmrc` + `prefix=/usr/local` no npmrc BUILTIN), o
  # `npm config set prefix …` retorna exit 0 e NÃO ESCREVE NADA: `~/.npmrc` nem é
  # criado e `npm config get prefix` segue devolvendo `/usr/local`. A guarda acima
  # disparava certo e o efeito dela era descartado em silêncio — o `npm i -g` ia p/
  # `/usr/local` e estourava EACCES do mesmo jeito. Medido: com `--location=user` o
  # arquivo é criado e o prefix passa a valer; sem ele, nada acontece.
  # Best-effort: se falhar, o `--prefix` do install abaixo ainda garante o destino.
  npm config set prefix "$PREFIX" --location=user 2>/dev/null || true
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
step "2/2" "$(t s2)"
sub "$(t s2.a)"
sub "$(t s2.b)"
sub "$(t s2.c)"
sub "$(t s2.d)"
# `--prefix "$PREFIX"` é a GARANTIA (não depende de config persistida): passa o destino
# NA PRÓPRIA chamada. É o que blinda contra o no-op do `npm config set` descrito acima —
# se por qualquer razão o prefix não persistir, o install AINDA vai p/ o lugar certo.
npm install -g --prefix "$PREFIX" "$PKG"

# Resolve o binário pelo caminho ABSOLUTO (não depende do PATH já estar "quente").
ALUY="$BIN/aluy"
[ -x "$ALUY" ] || ALUY="$(command -v aluy 2>/dev/null || true)"
[ -n "$ALUY" ] && [ -x "$ALUY" ] || die "aluy instalou mas não achei o binário em ${BIN} (rode: ls ${BIN})."

good "$(t done)"

# 3a) INSTALAÇÃO ÓRFÃ (com root) SOMBREANDO a nova. Cenário real: uma instalação
#     antiga feita com `sudo npm i -g` mora em `/usr/local/lib/node_modules` (dono
#     root). Como nós caímos para `~/.aluy-npm` (o prefix do root não é gravável), a
#     ANTIGA continua existindo e o `aluy` de `/usr/local/bin` segue no PATH. Nós
#     prependamos `$BIN`, então normalmente a nova ganha — mas basta um shell que
#     carregue os rc files em outra ordem (ou um PATH herdado por serviço/cron) p/ o
#     usuário rodar a VERSÃO VELHA sem perceber e reportar bugs já corrigidos.
#     Avisamos com o comando exato; NÃO removemos por conta própria (é `sudo`, e
#     apagar coisa do root sem pedir não é papel de um instalador).
SHADOWS="$(type -aP aluy 2>/dev/null | grep -vxF "$ALUY" || true)"
if [ -n "$SHADOWS" ]; then
  printf '\n'
  printf '  %s!%s  há outra instalação do aluy no PATH, além desta:\n' "$RED" "$RESET"
  printf '%s\n' "$SHADOWS" | while IFS= read -r s; do
    [ -n "$s" ] || continue
    v="$("$s" --version 2>/dev/null | head -1 || true)"
    sub "• $s${v:+  ($v)}"
  done
  sub "$(t this) $ALUY"
  sub "$(t shadow)"
  sub "$(t shadow2) $PKG"
fi

# 4) entrega pro ONBOARD (Node/Ink) reanexado ao TTY real (não ao stdin do pipe), e
#    depois entra na sessão. Usa o caminho ABSOLUTO ($ALUY) p/ não depender do PATH.
#    ALUY_ONBOARD_NO_LAUNCH=1 — a partir da rc.107 o `aluy onboard` PASSA a rodar o
#    bootstrap (perfil turbo) e a ABRIR a sessão ao final, cumprindo o "enter p/ entrar
#    no aluy" que a tela dele promete. Aqui a cadeia é NOSSA (as três etapas abaixo,
#    cada uma reanexada ao /dev/tty), então pedimos ao onboard p/ NÃO duplicá-la —
#    senão o bootstrap roda 2× e a sessão abre 2× em sequência.
#    Seguro contra skew de versão: um CLI ANTIGO simplesmente IGNORA a variável e a
#    cadeia daqui continua fazendo tudo, como sempre fez.
if [ -r /dev/tty ]; then
  clear
  ALUY_ONBOARD_NO_LAUNCH=1 "$ALUY" onboard < /dev/tty || true
  clear
  "$ALUY" bootstrap < /dev/tty || true
  clear
  good "$(t ready)"
  exec "$ALUY" < /dev/tty
else
  good "$(t ready2)"
fi
