"""Serve scoped benchmark artifacts with ranges and run Chrome/WebGL measurements."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import mimetypes
from pathlib import Path
import subprocess
import threading
from urllib.parse import unquote, urlsplit


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, required=True)
    p.add_argument('--vgs', type=Path, default=Path('D:/Trabajos/THE4DSCANNER/VGSFileFormat'))
    p.add_argument('--viewer', type=Path, default=Path('D:/Trabajos/ScanMeNow/SMNWebviewer/Playcanvas'))
    a = p.parse_args()
    roots = {'data': a.root.resolve(), 'tools': (a.root.parent / 'C12_webtools').resolve(),
             'bench': (a.vgs / 'experiments/temporal').resolve(), 'viewer': (a.viewer / 'src/vgs').resolve()}
    class Handler(BaseHTTPRequestHandler):
        def do_HEAD(self):
            self.serve(False)
        def do_GET(self):
            self.serve(True)
        def serve(self, body):
            path = unquote(urlsplit(self.path).path).lstrip('/')
            if not path:
                data = b'<!doctype html><title>VGS codec benchmark</title>'
                self.send_response(200); self.send_header('Content-Length', str(len(data))); self.end_headers()
                if body: self.wfile.write(data)
                return
            prefix, _, relative = path.partition('/')
            if prefix not in roots:
                self.send_error(404); return
            target = (roots[prefix] / relative).resolve()
            if not target.is_relative_to(roots[prefix]) or not target.is_file():
                self.send_error(404); return
            size = target.stat().st_size
            lo, hi = 0, size - 1
            partial = self.headers.get('Range')
            if partial:
                first, _, last = partial.removeprefix('bytes=').partition('-')
                lo, hi = int(first), int(last) if last else size-1
                if lo < 0 or hi < lo or lo >= size:
                    self.send_error(416); return
                hi = min(hi, size - 1)
            self.send_response(206 if partial else 200)
            self.send_header('Content-Type', 'text/javascript' if target.suffix in ('.js', '.mjs') else mimetypes.guess_type(target.name)[0] or 'application/octet-stream')
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Length', str(hi-lo+1))
            if partial: self.send_header('Content-Range', f'bytes {lo}-{hi}/{size}')
            self.end_headers()
            if body:
                with target.open('rb') as f:
                    f.seek(lo)
                    left = hi-lo+1
                    while left:
                        data = f.read(min(left, 1024*1024))
                        self.wfile.write(data); left -= len(data)
        def log_message(self, *_):
            pass
    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        subprocess.run(['node', str(a.vgs / 'experiments/temporal/web_runner.cjs'),
                        f'http://127.0.0.1:{server.server_port}/', str(a.root / 'web_metrics.json')], check=True)
    finally:
        server.shutdown(); server.server_close()
    print(json.dumps({'status': 'COMPLETE', 'out': str(a.root / 'web_metrics.json')}))


if __name__ == '__main__':
    main()
