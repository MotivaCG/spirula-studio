"""Measure fixed-scale representation error on existing PLYs; no rendering/GPU."""
import argparse
import json
from pathlib import Path
import sys

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from run_audit import read_ply, sha


def frames(tc, run):
    mapping = [r.split() for r in (tc / (run + ".seq")).read_text().splitlines() if r.strip()]
    plys = [tc / name / "frames" / f"{int(slot):03d}" / "splat.ply" for _, name, slot in mapping]
    first_props, first = read_ply(plys[0])
    n = len(first)
    scale = np.empty((len(plys), n, 3), np.float32)
    live = np.empty((len(plys), n), bool)
    for t, path in enumerate(plys):
        props, a = read_ply(path)
        if props != first_props or len(a) != n:
            raise ValueError(f"Layout/rows changed at {path}")
        scale[t] = a[:, [props.index(f"scale_{i}") for i in range(3)]]
        x = a[:, props.index("opacity")]
        live[t] = x > np.log(.1 / .9)
    return plys, scale, live


def measure(scale, live, intervals):
    errors = {"first": [], "median": []}
    changes = []
    blocks = []
    for start in range(0, len(scale) - 1, intervals):
        end = min(start + intervals + 1, len(scale))
        s, v = scale[start:end], live[start:end]
        stable = v.all(axis=0)
        blocks.append({"first": start, "last": end - 1, "persistent_rows": int(stable.sum())})
        if not stable.any():
            continue
        s = s[:, stable, :]
        for name, ref in (("first", s[0]), ("median", np.median(s, axis=0))):
            errors[name].append(np.max(abs(s - ref[None, :, :]), axis=2).ravel())
        changes.append(np.max(abs(s[1:] - s[:-1]), axis=2).ravel())
    result = {"intervals": intervals, "blocks": blocks}
    for name, vectors in errors.items():
        if not vectors:
            result[name] = None
            continue
        x = np.concatenate(vectors)
        result[name] = {"samples": len(x), "p50_abs_log": float(np.median(x)),
                        "p95_abs_log": float(np.quantile(x, .95)),
                        "over_1pct": float(np.mean(x > np.log1p(.01))),
                        "over_2pct": float(np.mean(x > np.log1p(.02))),
                        "over_5pct": float(np.mean(x > np.log1p(.05)))}
    if changes:
        x = np.concatenate(changes)
        result["consecutive_p95_abs_log"] = float(np.quantile(x, .95))
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--tc", type=Path, required=True)
    p.add_argument("--run", required=True)
    p.add_argument("--out", type=Path, required=True)
    a = p.parse_args()
    if a.out.exists():
        raise FileExistsError(a.out)
    plys, scale, live = frames(a.tc, a.run)
    result = {"run": a.run, "source": {str(path): sha(path) for path in plys},
              "scope": "All rows persistent over each block, including background. Row index is a proxy, not generation identity. Parameter error only; no render quality claim.",
              "chunks": [measure(scale, live, t) for t in (1, 2, 4, 8, 16, 32)]}
    a.out.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"run": a.run, "blocks": len(result["chunks"]), "out": str(a.out)}))


if __name__ == "__main__":
    main()
