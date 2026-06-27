# aluy-cli-site

Site de marketing e documentação do **Aluy CLI** — o time de agentes que vive no seu terminal.

> Repositório do **site**, separado do código do CLI (ADR-0131). Open source · MIT.
> O site **consome** os instaladores do Aluy CLI pela borda (download por URL em `aluy.dev`);
> não importa código do CLI nem entra no build do binário.

Redesenho de alta fidelidade no **tema escuro** do Aluy Design System (dark-only).

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

- `site.css` — folha **única** compartilhada (tokens do Aluy DS, tema escuro). Sem CSS por página.
- `site.js` — menu mobile. `install.js` — bloco de instalação (abas de SO + copiar; no Windows, terminal `cmd` extra). `help.js` — split do Docs (scroll-spy no painel de conteúdo). `lang.js` — i18n.
- `assets/` — wordmark oficial (PNG branco para o tema escuro).
- `install.sh` · `install.ps1` · `install.cmd` — instaladores servidos para download
  (`curl -fsSL https://aluy.dev/install.sh | bash` · `irm https://aluy.dev/install.ps1 | iex`).

## i18n

EN é o padrão e vive na raiz; PT-BR vive em `pt/`. O `lang.js` marca o idioma ativo no toggle EN/PT,
persiste a escolha em `localStorage` e redireciona para a página equivalente no outro idioma.

## Rodar local

```bash
python3 -m http.server 8080
# abra http://localhost:8080
```

Site estático — **sem build**.

## Licença

MIT — veja [LICENSE](LICENSE).
