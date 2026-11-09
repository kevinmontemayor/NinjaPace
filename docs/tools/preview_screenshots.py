#!/usr/bin/env python3
"""Local documentation preview. Demo data only; never starts the production relay.

Run from any directory: python3 docs/tools/preview_screenshots.py
Open http://127.0.0.1:8878/hud?theme=ninja&state=live
The served copy freezes elapsed interpolation and pulse for reproducible stills.
The shipped overlay.html is never modified.
"""
import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parents[2]
THEMES = ('ninja', 'viking', 'knight', 'pirate', 'cyborg', 'spartan')


def preset(theme):
    source = (ROOT / 'NinjaPace/App/AppTheme+HUDPreset.swift').read_text()
    block = source.split(f'case .{theme}:', 1)[1].split(')', 1)[0]
    config = {}
    for key, value in re.findall(r'(\w+):\s*("[^"]*"|[\d.]+)', block):
        config[key] = json.loads(value)
    config.update(themeKey=theme, borderEnabled=True, borderWidth=2, scale=1,
                  showMiles=True, showSteps=True, showHeartRate=True,
                  showCalories=True, showElapsed=True, showPace=True, showGoal=True)
    for state, opacity in [('live', 0), ('paused', .78), ('idle', .55), ('goal', .88)]:
        config[state + 'BackgroundColor'] = '#101014'
        config[state + 'BackgroundOpacity'] = opacity
    return config


def fixture(theme, state, custom=False):
    config = preset(theme)
    if custom:
        # Same identity edits demonstrated in the Mac HUD Studio capture.
        config.update(title='ROAD TO FIVE', subtitle='Every mile counts',
                      pausedColor='#FFCC00', idleColor='#B4B4B4', goalColor='#00FF78',
                      glowIntensity=.75)
    data = dict(theme=theme, running=state != 'idle', paused=state == 'paused',
                miles=3.14, steps=6240, hr=142, elapsed='00:28:10.00',
                elapsedSeconds=1690, elapsedMilliseconds=1690000, pace='8:58',
                activeCalories=418, totalCalories=518, goalMiles=5, progress=.63,
                hudConfiguration=config)
    if state == 'goal':
        data.update(miles=5, progress=1)
    return data


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlparse(self.path)
        args = parse_qs(url.query)
        theme = args.get('theme', ['ninja'])[0]
        state = args.get('state', ['live'])[0]
        if theme not in THEMES or state not in ('idle', 'live', 'paused', 'goal'):
            self.send_error(400)
            return
        if url.path == '/stats':
            body = json.dumps(fixture(theme, state, args.get('custom') == ['1'])).encode()
            mime = 'application/json'
        elif url.path == '/hud':
            html = (ROOT / 'NinjaPaceMac/overlay.html').read_text()
            html = html.replace('base + "/stats"', 'base + "/stats" + window.location.search')
            html = html.replace('const delta = performance.now() - elapsedClock.receivedAt;',
                                'const delta = 0; // Documentation still: freeze interpolation.')
            html = html.replace('</head>', '''<style>
                html,body { background:#0c1018; }
                .ring { top:40px; left:40px; }
                .ring::before { animation:none !important; }
                *, *::before, *::after { transition:none !important; }
                </style></head>''')
            if args.get('obs') == ['1']:
                html = html.replace('html,body { background:#0c1018; }', 'html,body { background:transparent; }').replace('top:40px; left:40px;', 'top:0; left:0;')
            body, mime = html.encode(), 'text/html; charset=utf-8'
        else:
            path = (ROOT / url.path.lstrip('/')).resolve()
            if not path.is_relative_to(ROOT / 'docs') or not path.is_file():
                self.send_error(404)
                return
            body = path.read_bytes()
            mime = 'image/png' if path.suffix == '.png' else 'text/html; charset=utf-8'
        self.send_response(200)
        self.send_header('Content-Type', mime)
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)


if __name__ == '__main__':
    print('Demo preview: http://127.0.0.1:8878/hud?theme=ninja&state=live', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8878), Handler).serve_forever()
