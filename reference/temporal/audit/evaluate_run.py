"""Evaluate a unique run using the existing metrics and per-run render cache."""
import argparse
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import evaluate as e
import population as pop


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--run", required=True)
    p.add_argument("--last", type=int, choices=[64, 76], required=True)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    e.HERE = str(HERE.parents[2] / "outputs/tc")
    e.set_frames(45, args.last)
    tag = args.run + ".seq"
    plys = [(ply, frame) for ply, frame in pop.plys_of(tag, 45) if 45 <= frame <= args.last]
    if [f for _, f in plys] != e.FRAMES:
        raise ValueError("Frame mapping does not match evaluation range")
    fit, detail, coverage = [], [], {}
    for ply, frame in plys:
        name = f"{tag}_{frame}"
        fit.append(e.fit_quality(ply, frame, name))
        detail.append(e.detail_quality(name))
        if frame in {45, 60, args.last}:
            counts, cov = pop.measure(ply, frame)
            coverage[str(frame)] = {"coverage": cov, "counts_002_01_05": counts}
    flicker = e.render_flicker(tag)
    result = {"run": args.run, "frames": e.FRAMES, "fit": fit, "detail": detail,
              "fit_mean": sum(fit) / len(fit), "fit_final": fit[-1],
              "detail_mean": sum(detail) / len(detail),
              "flicker": float(flicker[3] * 1000),
              "flicker_pairs": [float(v * 1000) for v in flicker[4]], "coverage": coverage}
    args.out.write_text(json.dumps(result, indent=2, allow_nan=False), encoding="utf-8")
    print(json.dumps({k: result[k] for k in ("run", "fit_mean", "fit_final", "detail_mean", "flicker")}))


if __name__ == "__main__":
    main()
