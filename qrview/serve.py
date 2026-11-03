"""Live QR viewer for NapCat.

NapCat rewrites cache/qrcode.png every ~2 minutes while waiting for login.
This server serves that file with no-store headers and an auto-refreshing page,
so whatever the browser shows is the current code.

    python qrview/serve.py

Environment:
    NAPCAT_QR    path to qrcode.png (default: D:\\NapCat\\app\\napcat\\cache\\qrcode.png)
    QRVIEW_PORT  listen port (default: 8099)
"""

import http.server
import os
import socketserver

QR = os.environ.get("NAPCAT_QR", r"D:\NapCat\app\napcat\cache\qrcode.png")
PORT = int(os.environ.get("QRVIEW_PORT", "8099"))

HTML = """<!doctype html>
<html><head><meta charset="utf-8">
<meta http-equiv="refresh" content="2">
<title>NapCat login QR</title></head>
<body style="margin:0;background:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;font-family:sans-serif">
<img src="/qr.png" style="width:520px;height:520px;image-rendering:pixelated">
<div style="margin-top:16px;color:#666;font-size:14px">auto refresh every 2s</div>
</body></html>""".encode("utf-8")

MISSING = b"qrcode.png not found - check NAPCAT_QR and whether NapCat is waiting for login"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/qr.png"):
            try:
                with open(QR, "rb") as f:
                    data = f.read()
                status = 200
            except OSError:
                data = MISSING
                status = 404
            self.send_response(status)
            self.send_header("Content-Type", "image/png" if status == 200 else "text/plain; charset=utf-8")
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
            self.send_header("Pragma", "no-cache")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(HTML)

    def log_message(self, *args):
        pass


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as srv:
    print(f"QR viewer: http://127.0.0.1:{PORT}/  (source: {QR})", flush=True)
    srv.serve_forever()
