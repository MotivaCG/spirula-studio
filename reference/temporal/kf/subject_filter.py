"""Mask-consensus split of one frame's PLY (as Forge's static prune keeps the subject): a splat is
subject when its centre falls inside the dilated mask (training's boundary offset, 0.03) in at
least 85 % of the TRAINING cameras that see it, seen by 3 or more; the rest is room/floaters.
Usage: subject_filter.py <frame> <in.ply> <subject.ply> [<rest.ply> | --hide]
--hide keeps every row and makes the rest transparent, so a chunk's frames keep one splat list."""
import sys
import numpy as np
import ho_lib as H

f, src, out = int(sys.argv[1]), sys.argv[2], sys.argv[3]
rest_out = sys.argv[4] if len(sys.argv) > 4 else None
hide = rest_out == "--hide"
DOWN = 4
head, rows, props = H.read_ply(src)
X = rows[:, [props.index(c) for c in "xyz"]].astype(np.float64)
cams, imgs = H.read_cameras(f"{H.frame_dir(f)}/sparse/cameras.bin"), H.read_images(f"{H.frame_dir(f)}/sparse/images.bin")
hold = set(H.held_out(f))
seen = np.zeros(len(X), np.int32); inside = np.zeros(len(X), np.int32)
for name, (q, t, cid, _) in imgs.items():
    if name in hold: continue
    model, w, h, p = cams[cid]
    fx, fy, cx, cy = (p[0], p[0], p[1], p[2]) if model == 0 else p[:4]
    m = H.mask(f, name, DOWN, 0.03)
    sx, sy = m.shape[1] / w, m.shape[0] / h
    Xc = X @ H.qrot(q).T + t
    z = Xc[:, 2]; ok = z > 0.05
    u = np.where(ok, (fx * Xc[:, 0] / np.where(ok, z, 1) + cx) * sx, -1).astype(np.int64)
    v = np.where(ok, (fy * Xc[:, 1] / np.where(ok, z, 1) + cy) * sy, -1).astype(np.int64)
    vis = ok & (u >= 0) & (u < m.shape[1]) & (v >= 0) & (v < m.shape[0])
    seen += vis
    inside[vis] += m[v[vis], u[vis]]
keep = (seen >= 3) & (inside >= 0.85 * np.maximum(seen, 1))
if hide:
    shown = rows.copy(); shown[~keep, props.index("opacity")] = -30.0
    H.write_ply(out, head, shown)
else:
    H.write_ply(out, head, rows[keep])
    if rest_out: H.write_ply(rest_out, head, rows[~keep])
op = 1 / (1 + np.exp(-rows[:, props.index("opacity")]))
print(f"{src}: {len(rows)} rows, subject {keep.sum()}, rest {(~keep).sum()} (of which visible {((~keep) & (op > 1 / 255)).sum()})")
