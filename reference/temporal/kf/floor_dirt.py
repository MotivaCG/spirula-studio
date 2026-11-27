"""Floor dirt per run: splats shown (alpha > 1/255, the .vgs threshold) near the floor (y up,
floor at y ~ 0, metres), under 3 cm (and how many of those are faint, alpha < 0.1) and under 10 cm.
Usage: floor_dirt.py <run>... (runs as <run>/frames/NNN/splat.ply in outputs/tc)"""
import os, sys
sys.path[:0] = [os.path.dirname(os.path.abspath(__file__))]
import numpy as np
import ho_lib as H

TC = "D:/Dependencias/spirula-studio/outputs/tc"
print("frame | " + " | ".join(f"{r}: shown, y<3cm (faint), y<10cm" for r in sys.argv[1:]))
for k in (0, 10, 20, 28):
    out = []
    for run in sys.argv[1:]:
        _, r, p = H.read_ply(f"{TC}/{run}/frames/{k:03d}/splat.ply")
        c = {n: i for i, n in enumerate(p)}
        op = 1 / (1 + np.exp(-r[:, c["opacity"]].astype(np.float64)))
        s = op > 1 / 255
        y, o = r[s, c["y"]], op[s]
        out.append(f"{int(s.sum())}, {int((y < 0.03).sum())} ({int(((y < 0.03) & (o < 0.1)).sum())}), {int((y < 0.10).sum())}")
    print(f"{45 + k} | " + " | ".join(out), flush=True)
