#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Carimba a versão dos arquivos de estilo e de script nas páginas.

POR QUE ISTO EXISTE
-------------------
O GitHub Pages manda `Cache-Control: max-age=600` e não deixa mudar. O HTML
guardado por dez minutos é chato mas passa. O que não passa é HTML novo com
CSS velho: o navegador busca a página nova, reaproveita o `site.css` antigo
que ainda está no disco dele, e o resultado é um layout que nunca existiu em
lugar nenhum — aconteceu neste site e custou meia hora de diagnóstico errado.

Com `site.css?v=a1b2c3d4`, mudar o arquivo muda a URL, e uma URL nova não tem
cópia guardada. O hash é POR ARQUIVO: mexer no estilo não invalida o script.

COMO USAR
---------
    python scripts/versionar.py          # carimba e diz o que mudou
    python scripts/versionar.py --check  # só confere; sai 1 se faltar carimbo

Rode ANTES de commitar, sempre que tocar num .css ou .js.
"""
import hashlib
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
# `href="site.css"`, `src="../site.js"`, com ou sem carimbo anterior
REF = re.compile(r'((?:href|src)=")((?:\.\./)?)([\w.-]+\.(?:css|js))(?:\?v=[0-9a-f]+)?(")')


def versao(caminho: pathlib.Path) -> str:
    """Oito dígitos do sha-256 do conteúdo. Muda o arquivo, muda a URL."""
    return hashlib.sha256(caminho.read_bytes()).hexdigest()[:8]


def paginas():
    return sorted(list(RAIZ.glob('*.html')) + list((RAIZ / 'pt').glob('*.html')))


def main() -> int:
    conferir = '--check' in sys.argv
    cache: dict[str, str] = {}
    faltando: list[str] = []
    tocados = 0

    for pagina in paginas():
        texto = original = pagina.read_text(encoding='utf-8')

        def carimba(m: re.Match) -> str:
            prefixo, subida, arquivo, fecha = m.groups()
            alvo = RAIZ / arquivo
            if not alvo.exists():          # arquivo de terceiro, deixa quieto
                return m.group(0)
            if arquivo not in cache:
                cache[arquivo] = versao(alvo)
            return f'{prefixo}{subida}{arquivo}?v={cache[arquivo]}{fecha}'

        texto = REF.sub(carimba, texto)
        if texto != original:
            rel = pagina.relative_to(RAIZ).as_posix()
            if conferir:
                faltando.append(rel)
            else:
                pagina.write_text(texto, encoding='utf-8')
                tocados += 1
                print(f'  carimbada  {rel}')

    if conferir:
        if faltando:
            print('Sem carimbo, ou com carimbo velho:')
            for f in faltando:
                print(f'  {f}')
            print('\nRode: python scripts/versionar.py')
            return 1
        print(f'Todas as {len(paginas())} páginas com o carimbo em dia.')
        return 0

    print(f'\n{tocados} página(s) atualizada(s). Versões:')
    for arquivo, v in sorted(cache.items()):
        print(f'  {arquivo:<14} {v}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
