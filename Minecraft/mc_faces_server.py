#!/usr/bin/env python3
"""
Minecraft Online Players + Faces Web Server (Java Edition)

What it does
- Polls a Minecraft Java server using STATUS ping (server.status()).
- If the server exposes player sample names, it renders a web page showing:
  - who is online
  - each player's face (cropped from their skin)
- Runs a small local web server on a non-common port (default 8765).

Install
  python3 -m pip install mcstatus requests pillow

Run
  python3 mc_faces_server.py --host YOUR_SERVER_IP --port 25565 --web-port 8765

Open
  http://localhost:8765/

Notes
- Many servers hide player names; if status.players.sample is None, you'll only get counts.
- This script uses Mojang + sessionserver APIs, which apply to Java Edition.
"""

import argparse
import base64
import html
import json
import time
from io import BytesIO
from urllib.parse import urlparse, parse_qs

import requests
from mcstatus import JavaServer
from PIL import Image
from http.server import BaseHTTPRequestHandler, HTTPServer


DEFAULT_REFRESH_SECONDS = 10
HTTP_TIMEOUT = 10

# Caches (in-memory)
_name_to_uuid_cache = {}       # name.lower() -> (uuid, ts)
_uuid_to_skinurl_cache = {}    # uuid -> (skin_url, ts)
_face_png_cache = {}           # (uuid, size, hat) -> (png_bytes, ts)

CACHE_TTL_SECONDS = 60 * 60  # 1 hour


def _now() -> float:
    return time.time()


def _cache_get(cache: dict, key):
    item = cache.get(key)
    if not item:
        return None
    value, ts = item
    if _now() - ts > CACHE_TTL_SECONDS:
        cache.pop(key, None)
        return None
    return value


def _cache_set(cache: dict, key, value):
    cache[key] = (value, _now())


def mojang_uuid_from_name(name: str) -> str:
    cached = _cache_get(_name_to_uuid_cache, name.lower())
    if cached:
        return cached

    r = requests.get(f"https://api.mojang.com/users/profiles/minecraft/{name}", timeout=HTTP_TIMEOUT)
    if r.status_code == 204:
        raise ValueError(f"Player not found: {name}")
    r.raise_for_status()
    uuid_no_dashes = r.json()["id"]
    _cache_set(_name_to_uuid_cache, name.lower(), uuid_no_dashes)
    return uuid_no_dashes


def skin_url_from_uuid(uuid_no_dashes: str) -> str:
    cached = _cache_get(_uuid_to_skinurl_cache, uuid_no_dashes)
    if cached:
        return cached

    r = requests.get(
        f"https://sessionserver.mojang.com/session/minecraft/profile/{uuid_no_dashes}?unsigned=false",
        timeout=HTTP_TIMEOUT,
    )
    r.raise_for_status()
    data = r.json()

    props = data.get("properties", [])
    textures_prop = next((p for p in props if p.get("name") == "textures"), None)
    if not textures_prop:
        raise ValueError(f"No textures property for UUID {uuid_no_dashes}")

    decoded = base64.b64decode(textures_prop["value"]).decode("utf-8")
    textures_json = json.loads(decoded)
    skin = textures_json.get("textures", {}).get("SKIN", {})
    url = skin.get("url")
    if not url:
        raise ValueError(f"No skin URL for UUID {uuid_no_dashes}")

    _cache_set(_uuid_to_skinurl_cache, uuid_no_dashes, url)
    return url


def download_bytes(url: str) -> bytes:
    r = requests.get(url, timeout=HTTP_TIMEOUT)
    r.raise_for_status()
    return r.content


def face_png_from_skin(skin_png_bytes: bytes, size: int = 64, include_hat: bool = True) -> bytes:
    """
    Skin layout (classic):
      - Face/base: (8,8)-(16,16)
      - Hat/outer: (40,8)-(48,16)
    """
    skin = Image.open(BytesIO(skin_png_bytes)).convert("RGBA")

    face = skin.crop((8, 8, 16, 16))
    if include_hat:
        hat = skin.crop((40, 8, 48, 16))
        face.alpha_composite(hat)

    face = face.resize((size, size), resample=Image.NEAREST)

    out = BytesIO()
    face.save(out, format="PNG")
    return out.getvalue()


def get_status(mc_host: str, mc_port: int):
    """
    STATUS ping. This is what the Minecraft client uses for the server list.
    More commonly allowed than Query.
    """
    server = JavaServer(mc_host, mc_port)

    # Some mcstatus versions accept timeout=..., some don't.
    # Try with timeout first; fall back if needed.
    try:
        return server.status(timeout=3)
    except TypeError:
        return server.status()


def get_online_player_names_from_status(status_obj):
    """
    Extract names from status.players.sample if present.
    Returns list[str].
    """
    sample = getattr(status_obj.players, "sample", None)
    if not sample:
        return []

    names = []
    for p in sample:
        n = getattr(p, "name", None)
        if n:
            names.append(n)

    seen = set()
    out = []
    for n in names:
        if n not in seen:
            seen.add(n)
            out.append(n)
    return out


class McFacesHandler(BaseHTTPRequestHandler):
    server_version = "McFacesHTTP/1.1"

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        qs = parse_qs(parsed.query)

        if path == "/":
            self._handle_index(qs)
            return

        if path == "/face.png":
            self._handle_face(qs)
            return

        if path == "/health":
            self._send_text(200, "ok\n")
            return

        self._send_text(404, "not found\n")

    def _handle_index(self, qs):
        mc_host = self.server.mc_host
        mc_port = self.server.mc_port

        refresh = int(qs.get("refresh", [DEFAULT_REFRESH_SECONDS])[0])
        refresh = max(3, min(refresh, 120))

        title = f"Minecraft Online Players ({mc_host}:{mc_port})"
        escaped_title = html.escape(title)

        online = None
        max_players = None
        names = []
        error = None

        try:
            status = get_status(mc_host, mc_port)
            online = getattr(status.players, "online", None)
            max_players = getattr(status.players, "max", None)
            names = get_online_player_names_from_status(status)
        except Exception as e:
            error = str(e)

        rows = []

        if error:
            rows.append(f"<div class='error'>Status error: {html.escape(error)}</div>")

        if online is None:
            rows.append("<div class='empty'>Could not read player count.</div>")
        else:
            if max_players is None:
                rows.append(f"<div class='count'>Players online: {online}</div>")
            else:
                rows.append(f"<div class='count'>Players online: {online} / {max_players}</div>")

        if not names:
            rows.append("<div class='empty'>No player names available (server hides names, or none online).</div>")
        else:
            rows.append("<div class='grid'>")
            for name in names:
                ename = html.escape(name)
                img_url = f"/face.png?name={ename}&size=64&hat=1"
                rows.append(
                    "<div class='card'>"
                    f"<img class='face' src='{img_url}' width='64' height='64' alt='{ename}'>"
                    f"<div class='name'>{ename}</div>"
                    "</div>"
                )
            rows.append("</div>")

        body = "\n".join(rows)

        page = f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="{refresh}">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{escaped_title}</title>
  <style>
    body {{
      font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
      margin: 20px;
      background: #0b0b0c;
      color: #e8e8ea;
    }}
    .header {{
      display: flex;
      gap: 12px;
      align-items: baseline;
      justify-content: space-between;
      flex-wrap: wrap;
      margin-bottom: 16px;
    }}
    .title {{
      font-size: 18px;
      font-weight: 600;
    }}
    .meta {{
      font-size: 13px;
      color: #b7b7bd;
    }}
    .count {{
      background: #141416;
      border: 1px solid #232327;
      padding: 10px;
      border-radius: 10px;
      display: inline-block;
    }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
      gap: 12px;
      margin-top: 12px;
    }}
    .card {{
      background: #141416;
      border: 1px solid #232327;
      border-radius: 10px;
      padding: 12px;
      display: grid;
      grid-template-columns: 64px 1fr;
      gap: 10px;
      align-items: center;
    }}
    .face {{
      image-rendering: pixelated;
      border-radius: 8px;
      background: #0f0f11;
      border: 1px solid #232327;
    }}
    .name {{
      font-size: 14px;
      font-weight: 600;
      word-break: break-word;
    }}
    .error {{
      background: #2b1111;
      border: 1px solid #5b1c1c;
      padding: 10px;
      border-radius: 10px;
      color: #ffd6d6;
      margin-bottom: 10px;
    }}
    .empty {{
      background: #141416;
      border: 1px solid #232327;
      padding: 10px;
      border-radius: 10px;
      color: #b7b7bd;
      margin-top: 10px;
    }}
    a {{
      color: #9ecbff;
      text-decoration: none;
    }}
    a:hover {{
      text-decoration: underline;
    }}
  </style>
</head>
<body>
  <div class="header">
    <div class="title">{escaped_title}</div>
    <div class="meta">
      Auto-refresh: {refresh}s
      | <a href="/health">health</a>
    </div>
  </div>
  {body}
</body>
</html>
"""
        self._send_html(200, page)

    def _handle_face(self, qs):
        name = (qs.get("name", [""])[0] or "").strip()
        if not name:
            self._send_text(400, "missing name\n")
            return

        try:
            size = int(qs.get("size", ["64"])[0])
        except ValueError:
            size = 64
        size = max(16, min(size, 256))

        hat = qs.get("hat", ["1"])[0] in ("1", "true", "yes", "on")

        try:
            uuid = mojang_uuid_from_name(name)
            cache_key = (uuid, size, hat)

            cached_png = _cache_get(_face_png_cache, cache_key)
            if cached_png:
                self._send_png(200, cached_png)
                return

            skin_url = skin_url_from_uuid(uuid)
            skin_bytes = download_bytes(skin_url)
            face_png = face_png_from_skin(skin_bytes, size=size, include_hat=hat)

            _cache_set(_face_png_cache, cache_key, face_png)
            self._send_png(200, face_png)
        except Exception:
            # 1x1 transparent png if anything fails
            transparent_1x1 = base64.b64decode(
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/6X9o3sAAAAASUVORK5CYII="
            )
            self._send_png(200, transparent_1x1)

    def _send_html(self, code: int, content: str):
        data = content.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_text(self, code: int, content: str):
        data = content.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_png(self, code: int, png_bytes: bytes):
        self.send_response(code)
        self.send_header("Content-Type", "image/png")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(png_bytes)))
        self.end_headers()
        self.wfile.write(png_bytes)

    def log_message(self, fmt, *args):
        return


class McFacesHTTPServer(HTTPServer):
    def __init__(self, server_address, RequestHandlerClass, mc_host: str, mc_port: int):
        super().__init__(server_address, RequestHandlerClass)
        self.mc_host = mc_host
        self.mc_port = mc_port


def main():
    ap = argparse.ArgumentParser(description="Tiny web server showing online MC players + face images (Java Edition).")
    ap.add_argument("--host", required=True, help="Minecraft server host/IP")
    ap.add_argument("--port", type=int, default=25565, help="Minecraft server port (default 25565)")
    ap.add_argument("--web-port", type=int, default=8765, help="Web server port (default 8765)")
    ap.add_argument(
        "--bind",
        default="127.0.0.1",
        help="Bind address (default 127.0.0.1). Use 0.0.0.0 to expose on LAN.",
    )
    args = ap.parse_args()

    httpd = McFacesHTTPServer((args.bind, args.web_port), McFacesHandler, mc_host=args.host, mc_port=args.port)
    print(f"Serving http://{args.bind}:{args.web_port}/  (MC: {args.host}:{args.port})")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
