#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Servidor do site para desenvolvimento, sem cache nenhum.

POR QUE ISTO EXISTE
-------------------
O `python -m http.server` manda `Last-Modified` e responde 304. O navegador
então guarda a página por uma fração do tempo desde a última modificação — e
passa a servir do disco dele sem perguntar nada. No desenvolvimento isso é
veneno: você corrige, recarrega, e vê a versão de antes.

Isso aconteceu neste projeto o dia inteiro. Em um dos casos o navegador
mostrou uma navegação que não existe no repositório há meses, e o diagnóstico
foi para o lado errado duas vezes antes de alguém olhar os bytes.

Aqui toda resposta sai com `Cache-Control: no-store`: o navegador é proibido
de guardar. Em produção o GitHub Pages continua com o cache dele, que é o
comportamento certo lá — e para isso existe o `scripts/versionar.py`.

    python scripts/servir.py [porta]      # padrão 8087
"""
import functools
import http.server
import pathlib
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent


class SemCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def send_response(self, code, message=None):
        """Sem `Last-Modified` não há revalidação heurística para o navegador
        se apoiar — é a mesma trava, pelo outro lado."""
        super().send_response(code, message)

    def send_header(self, keyword, value):
        if keyword.lower() == 'last-modified':
            return
        super().send_header(keyword, value)

    def log_message(self, fmt, *args):
        super().log_message(fmt, *args)


def main() -> int:
    porta = int(sys.argv[1]) if len(sys.argv) > 1 else 8087
    handler = functools.partial(SemCache, directory=str(RAIZ))
    # ThreadingHTTPServer, nao TCPServer: o de uma conexao so trava quando o
    # navegador segura o soquete aberto — o resto fica na fila para sempre.
    http.server.ThreadingHTTPServer.allow_reuse_address = True
    with http.server.ThreadingHTTPServer(('', porta), handler) as s:
        print(f'servindo {RAIZ} em http://localhost:{porta} — sem cache')
        try:
            s.serve_forever()
        except KeyboardInterrupt:
            print('\nparado')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
