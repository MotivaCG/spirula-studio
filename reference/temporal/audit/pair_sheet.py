"""Create a fixed-camera contact sheet from cached renders only."""
import argparse
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import evaluate as e


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--tc", type=Path, required=True)
    p.add_argument("--camera", required=True)
    p.add_argument("--frames", nargs="+", type=int, required=True)
    p.add_argument("--runs", nargs="+", required=True)
    p.add_argument("--out", type=Path, required=True)
    a = p.parse_args()
    if a.out.exists():
        raise FileExistsError(a.out)
    e.HERE = str(a.tc.resolve())
    panels = []
    for frame in a.frames:
        row = []
        for run in a.runs:
            q = a.tc / "q" / f"{run}.seq_{frame}"
            view = e.camera_views(str(q))
            if a.camera not in view:
                raise ValueError(f"{a.camera} missing in {q}")
            idx, _ = view[a.camera]
            if not row:
                row.append(Image.open(q / f"eval-gt-{idx:05d}.png").convert("RGB"))
            row.append(Image.open(q / f"eval-render-{idx:05d}.png").convert("RGB"))
        panels.append(row)
    width = 420
    height = int(panels[0][0].height * width / panels[0][0].width)
    margin = 27
    canvas = Image.new("RGB", (len(panels[0]) * width, len(panels) * (height + margin)), "white")
    draw = ImageDraw.Draw(canvas)
    for row_idx, row in enumerate(panels):
        for col_idx, picture in enumerate(row):
            picture = picture.resize((width, height), Image.Resampling.LANCZOS)
            x = col_idx * width
            y = row_idx * (height + margin)
            canvas.paste(picture, (x, y + margin))
            label = "video" if col_idx == 0 else a.runs[col_idx - 1]
            draw.text((x + 4, y + 5), f"{a.frames[row_idx]} {label}", fill="black")
    canvas.save(a.out)
    print(a.out)


if __name__ == "__main__":
    main()
