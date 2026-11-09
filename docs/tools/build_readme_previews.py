#!/usr/bin/env python3
"""Create compact README previews while preserving original screenshot assets.

Uses macOS sips. Run again after recapturing source images.
"""
from pathlib import Path
import subprocess
import re

ROOT = Path(__file__).resolve().parents[2]
IMAGES = ROOT / 'docs/images'
PREVIEWS = IMAGES / 'previews'


def build():
    PREVIEWS.mkdir(exist_ok=True)
    guides = [ROOT / 'README.md', ROOT / 'NinjaPace/README.md',
              ROOT / 'NinjaPaceMac/README.md', ROOT / 'NinjaPaceWatch/README.md',
              ROOT / 'docs/README-Streaming-HUD.md']
    referenced = set()
    for guide in guides:
        referenced.update(re.findall(r'images/(hero|hud|iphone|watch|mac)/([\w-]+\.png)',
                                     guide.read_text()))
    for category, name in sorted(referenced):
        source = IMAGES / category / name
        # Small app images wrap naturally in ordinary Markdown paragraphs.
        width = 200 if category in ('iphone', 'watch', 'mac') else 640
        if name in ('monthly-badges-locked.png', 'monthly-badges-unlocked.png'):
            width = 320
        if name == 'duo-welcome-expanded.png':
            width = 640
        subprocess.run(
            ['sips', '--resampleWidth', str(width), str(source),
             '--out', str(PREVIEWS / source.name)],
            check=True, stdout=subprocess.DEVNULL,
        )


if __name__ == '__main__':
    build()
