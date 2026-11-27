"""Position vibration (2nd difference over frames, records alive in all three, alpha > 0.1) of
chunk runs saved as <run>/frames/NNN/splat.ply + birth_events.tsv. Usage: vib_runs.py RM0 ST7 ..."""
import sys
import numpy as np

TC = "D:/Dependencias/spirula-studio/outputs/tc"
sys.path.insert(0, "D:/Dependencias/spirula-studio/reference/temporal")
import flicker_lib as fl

for run in sys.argv[1:]:
    F = [fl.ply_frame(f"{TC}/{run}/frames/{k:03d}/splat.ply") for k in range(32)]
    gen = np.zeros((32, len(F[0]["opa"])), np.int64)
    for f, r, g in np.loadtxt(f"{TC}/{run}/frames/birth_events.tsv", dtype=np.int64, ndmin=2):
        gen[f:, r] = g
    d2, c1, c2 = [], [], []
    for t in range(1, 31):
        A, B, C = F[t - 1], F[t], F[t + 1]
        m = (gen[t - 1] == gen[t]) & (gen[t] == gen[t + 1]) & (A["opa"] > .1) & (B["opa"] > .1) & (C["opa"] > .1)
        d2.append(np.linalg.norm(C["pos"][m] - 2 * B["pos"][m] + A["pos"][m], axis=1))
        c1.append(np.abs(C["col"][m] - B["col"][m]).mean(1))
        c2.append(np.abs(C["col"][m] - 2 * B["col"][m] + A["col"][m]).mean(1))
    d2, c1, c2 = np.concatenate(d2) * 1000, np.concatenate(c1), np.concatenate(c2)
    # Light drift: the opacity-weighted mean colour of each frame.
    lum = [float((f["col"].mean(1) * f["opa"]).sum() / f["opa"].sum()) for f in F]
    print(f"{run}: vibration median {np.median(d2):.2f} mm, p90 {np.percentile(d2, 90):.2f} mm | "
          f"colour step mean {c1.mean():.4f}, colour 2nd diff median {np.median(c2):.4f} p90 "
          f"{np.percentile(c2, 90):.4f} | mean colour range {max(lum) - min(lum):.4f}")
