#!/usr/bin/env python3
"""Export the WatchDocumentationScreenshots gallery from an Xcode result bundle.

Usage: python3 docs/tools/export_watch_screenshots.py /path/to/gallery.xcresult
Set DEVELOPER_DIR if the capture used a non-default Xcode installation.
"""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
EXPECTED = {
    "watch-v2-home-" + theme
    for theme in ("ninja", "viking", "knight", "pirate", "cyborg", "spartan", "ready", "paused")
} | {
    "watch-v2-overview", "watch-v2-distance", "watch-v2-heart-rate",
    "watch-v2-controls", "watch-v2-settings", "watch-v2-warrior-picker",
}


def export(result: Path):
    with tempfile.TemporaryDirectory(prefix="ninjapace-watch-gallery-") as temporary:
        attachments = Path(temporary) / "attachments"
        subprocess.run([
            "xcrun", "xcresulttool", "export", "attachments", "--path", str(result),
            "--output-path", str(attachments),
        ], check=True, stdout=subprocess.DEVNULL)
        captures = {}
        for test in json.loads((attachments / "manifest.json").read_text()):
            for item in test.get("attachments", []):
                if item.get("isAssociatedWithFailure"):
                    continue
                name = item.get("suggestedHumanReadableName", "")
                for stem in EXPECTED:
                    if name.startswith(stem + "_") and name.endswith(".png"):
                        captures[stem] = attachments / Path(item["exportedFileName"]).name
        missing = EXPECTED - captures.keys()
        if missing:
            raise SystemExit("Missing gallery captures: " + ", ".join(sorted(missing)))

        originals = ROOT / "docs/images/watch"
        previews = ROOT / "docs/images/previews"
        originals.mkdir(parents=True, exist_ok=True)
        previews.mkdir(parents=True, exist_ok=True)
        for stem, capture in sorted(captures.items()):
            destination = originals / (stem + ".png")
            shutil.copy2(capture, destination)
            subprocess.run([
                "sips", "--resampleWidth", "200", str(destination),
                "--out", str(previews / destination.name),
            ], check=True, stdout=subprocess.DEVNULL)
        print(f"Exported {len(captures)} original screenshots and 200px README previews.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("result", type=Path, help="Xcode .xcresult bundle")
    export(parser.parse_args().result)
