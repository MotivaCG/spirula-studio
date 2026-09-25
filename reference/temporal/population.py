"""Subject population per frame: live splats at several opacity thresholds, and coverage.

python population.py <first> <run | name.seq> ...
Coverage = share of the frame's SfM points on the subject with a splat of opacity
> 0.1 within 1 cm: surface actually covered, which raising opacities cannot fake.
"""
import glob, os, struct, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import evaluate as e

THRESHOLDS = (0.02, 0.1, 0.5)


def subject_points(frame):
    out = []
    with open(f"{e.frame_dir(frame)}/sparse/points3D.bin", "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            _, x, y, z, _, _, _, _ = struct.unpack("<QdddBBBd", f.read(43))
            tl = struct.unpack("<Q", f.read(8))[0]; f.seek(tl * 8, 1)
            out.append((x, y, z))
    p = np.array(out)
    return p[e.hull.subject(p, e.frame_dir(frame), ratio=0.8, min_views=6)]


def nearest_dist(q, pts, cell=0.01):
    """Distance from each q to the nearest of pts, capped at one cell (a grid, no scipy)."""
    key = lambda c: (c[:, 0] + 2**20) * 2**42 + (c[:, 1] + 2**20) * 2**21 + (c[:, 2] + 2**20)
    kp = key(np.floor(pts / cell).astype(np.int64)); order = np.argsort(kp); kp = kp[order]
    uk, start, count = np.unique(kp, return_index=True, return_counts=True)
    cq = np.floor(q / cell).astype(np.int64); best = np.full(len(q), cell)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                kq = key(cq + np.array([dx, dy, dz]))
                loc = np.clip(np.searchsorted(uk, kq), 0, len(uk) - 1); hit = uk[loc] == kq
                s = np.where(hit, start[loc], 0); c = np.where(hit, count[loc], 0)
                for j in range(int(c.max()) if len(c) else 0):
                    qi = np.nonzero(c > j)[0]
                    d = np.linalg.norm(q[qi] - pts[order[s[qi] + j]], axis=1)
                    best[qi] = np.minimum(best[qi], d)
    return best


def measure(ply, frame):
    F = e.fl.ply_frame(ply); m = e.hull.subject(F["pos"], e.frame_dir(frame))
    counts = [int(((F["opa"] > t) & m).sum()) for t in THRESHOLDS]
    live = F["pos"][m & (F["opa"] > 0.1)]
    cov = float((nearest_dist(subject_points(frame), live) < 0.01).mean())
    return counts, cov


def plys_of(run, first):
    if run.endswith(".seq"):
        rows = [l.split() for l in open(f"{e.HERE}/{run}")]
        out = []
        for f, r, i in rows:
            d = f"{e.HERE}/{r}/frames/{int(i):03d}/splat.ply"
            out.append((d if os.path.exists(d) else sorted(glob.glob(f"{e.HERE}/{r}/step-*.ckpt"))[-1] + "/splat.ply", int(f)))
        return out
    if run == "forge":
        return [(sorted(glob.glob(f"{e.frame_dir(f)}/smn/step-*.ckpt/splat.ply"))[-1], f) for f in e.FRAMES]
    dirs = sorted(glob.glob(f"{e.HERE}/{run}/frames/[0-9][0-9][0-9]"))
    if dirs:
        return [(f"{d}/splat.ply", first + i) for i, d in enumerate(dirs)]
    return [(sorted(glob.glob(f"{e.HERE}/{run}/step-*.ckpt"))[-1] + "/splat.ply", first)]


if __name__ == "__main__":
    first = int(sys.argv[1])
    for run in sys.argv[2:]:
        if run == "forge":
            e.set_frames(first, first + 10)
        cells = []
        for ply, f in plys_of(run, first):
            (a, b, c), cov = measure(ply, f)
            cells.append(f"{f}:{a // 1000}/{b // 1000}/{c // 1000}k cov{cov * 100:.0f}%")
        print(f"{run:10s} " + "  ".join(cells), flush=True)
