"""Serve the Web export on loopback only. Run: python tools/serve.py"""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import webbrowser

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8765)
parser.add_argument('--open', action='store_true', help='Open the game in your default browser')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1] / 'build' / 'web'
if not (root / 'index.html').exists():
    raise SystemExit('Export the Web preset in Godot first.')
handler = partial(SimpleHTTPRequestHandler, directory=str(root))
print(f'VECTOR WING: http://127.0.0.1:{args.port}', flush=True)
try:
    server = ThreadingHTTPServer(('127.0.0.1', args.port), handler)
except OSError as error:
    raise SystemExit(f'Cannot start server on port {args.port}: {error}. Try --port 8766.')
if args.open:
    webbrowser.open(f'http://127.0.0.1:{args.port}')
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
