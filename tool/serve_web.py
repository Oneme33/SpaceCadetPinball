#!/usr/bin/env python3
"""Serves a web build locally the way space-cadet.nl serves the game:
cross-origin isolated (COOP/COEP), so the audio engine renders on its own
AudioWorklet thread instead of the page's main thread, and never cached.

  python3 tool/serve_web.py [dir] [port]     defaults: build/web 8123
"""
import functools
import http.server
import sys


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'credentialless')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


Handler.extensions_map.update({'.wasm': 'application/wasm', '.mjs': 'text/javascript'})

if __name__ == '__main__':
    root = sys.argv[1] if len(sys.argv) > 1 else 'build/web'
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8123
    http.server.ThreadingHTTPServer(
        ('', port), functools.partial(Handler, directory=root)
    ).serve_forever()
