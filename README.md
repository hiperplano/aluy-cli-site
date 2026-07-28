<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/hiperplano/aluy-cli-site/master/assets/aluy-wordmark-white.png">
    <img src="https://raw.githubusercontent.com/hiperplano/aluy-cli-site/master/assets/aluy-wordmark-ink.png" alt="Aluy" height="56">
  </picture>
</p>

<h1 align="center">aluy-cli-site</h1>

<p align="center">
  Site de marketing e documentação do <b>Aluy CLI</b> — o time de agentes que vive no seu terminal.
</p>

---

Repositório do **site**, separado do código do CLI (ADR-0131). Open source · MIT.
O site **consome** os instaladores do Aluy CLI pela borda (download por URL em
`aluy.dev`); não importa código do CLI nem entra no build do binário.

Site estático de alta fidelidade no **tema claro "papel"** do Aluy Design System:
superfícies em creme, âmbar dividido entre texto (`#9A5F0B`) e preenchimento
(`#DDA13F`), e o terminal como o **único** objeto escuro da página. Uma folha de
estilo, sem build, sem framework.

## Estrutura

6 páginas, cada uma em **EN (raiz)** e **PT-BR (`pt/`)**:

| Página | EN | PT |
|---|---|---|
| Home | `index.html` | `pt/index.html` |
| Features | `funcionalidades.html` | `pt/funcionalidades.html` |
| Commands | `comandos.html` | `pt/comandos.html` |
| Architecture | `arquitetura.html` | `pt/arquitetura.html` |
| Install | `comecar.html` | `pt/comecar.html` |
| Docs | `help.html` | `pt/help.html` |

Além dessas: `turbo.html` (modo turbo) e `termos.html` (termos), também em `pt/`.

## Scripts

Sem bundler nem dependências — cada arquivo é um script clássico, carregado direto
pelas páginas e compartilhado entre EN e `pt/`:

| Arquivo | Papel |
|---|---|
| `site.js` | Menu mobile e comportamento base da navegação. |
| `install.js` | Bloco de instalação: abas de SO (Linux/macOS · Windows) + botões de copiar. No Windows, mostra um terminal `cmd` extra. Fonte única do comando de instalação (host `aluy.dev`). |
| `help.js` | Split do Docs: scroll-spy no painel de conteúdo, com TOC que acompanha a rolagem. |
| `lang.js` | i18n — toggle EN/PT, persistência e redirecionamento para a página equivalente. |
| `consent.js` | Banner de consentimento + carregamento condicional do Google Analytics. |

## Estilo

- `site.css` — folha **única** compartilhada (tokens do Aluy DS, tema claro). Sem CSS por página.
- `assets/` — wordmark oficial: `aluy-wordmark-ink.png` para o tema claro · `aluy-wordmark-white.png` para fundos escuros · `og.png` para social preview.

## i18n

EN é o padrão e vive na raiz; PT-BR vive em `pt/`. O `lang.js` marca o idioma ativo no toggle EN/PT,
persiste a escolha em `localStorage` e redireciona para a página equivalente no outro idioma.

## Instaladores (borda)

O site **serve** os instaladores do Aluy CLI para download — ele não os constrói.
Comando único, resolvido pelo `install.js` a partir do host `aluy.dev`:

```bash
curl -fsSL https://aluy.dev/install.sh | bash    # Linux · macOS
irm https://aluy.dev/install.ps1 | iex           # Windows (PowerShell)
```

`install.sh` · `install.ps1` · `install.cmd` são servidos com o `Content-Type`
correto (via `netlify.toml` / `vercel.json`) para que `curl … | bash` e
`irm … | iex` funcionem e o navegador mostre o script em vez de baixar um blob.

## Rodar local

```bash
python3 -m http.server 8080
# abra http://localhost:8080
```

Site estático — **sem build**.

## Deploy

Publica a **raiz do repo como está** — nenhuma etapa de build. Suporta Netlify e
Vercel; o `.nojekyll` desliga o processamento do GitHub Pages.

| Item | Valor |
|---|---|
| Domínio (`CNAME`) | `aluy.dev` |
| Publish dir | `.` (raiz) |
| Build | nenhum |
| Headers | `Content-Type` dos instaladores (`netlify.toml` · `vercel.json`) |

## Privacidade

O Google Analytics (`consent.js`) só carrega **depois** que o visitante aceita no
banner. A escolha fica em `localStorage` (`aluy-consent`: `granted` | `denied`) e é
compartilhada entre as páginas EN e `pt/`. Nenhum dado é usado para publicidade.

## Licença

MIT — veja [LICENSE](LICENSE).
