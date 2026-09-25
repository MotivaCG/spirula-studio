"""Deformation graphs between consecutive frames' sparse clouds, after Forge's GraciaWarp.

python warps.py <first> <last> <outdir>
Writes <outdir>/NNN.bin for take index NNN = f - first, the warp from frame f-1 to f:
int32 N, float32 bind_radius, then N rows of float32 [g(3), t(3), q_wxyz(4)].
"""
import os, struct, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hull

WORK = "C:/Users/Victor/Documents/Gracia4DGSConverter/VIDEOTIKI/output/.work"
NODES, NODE_NB, OUTER, SWEEPS, ARAP, MAX_CORR = 5000, 8, 10, 60, 1.5, 0.05


def cloud(frame):
    out = []
    with open(f"{WORK}/000000{frame}/undistorted/sparse/points3D.bin", "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            _, x, y, z, _, _, _, _ = struct.unpack("<QdddBBBd", f.read(43))
            tl = struct.unpack("<Q", f.read(8))[0]; f.seek(tl * 8, 1)
            out.append((x, y, z))
    p = np.array(out)
    # The subject only: the room's points are static and would anchor the graph.
    return p[hull.subject(p, f"{WORK}/000000{frame}/undistorted", ratio=0.8, min_views=6)]


class Grid:
    def __init__(self, pts, cell):
        self.p, self.c = pts, cell
        k = np.floor(pts / cell).astype(np.int64)
        self.key = lambda c: (c[..., 0] + 2**20) * 2**42 + (c[..., 1] + 2**20) * 2**21 + (c[..., 2] + 2**20)
        kk = self.key(k); self.order = np.argsort(kk); kk = kk[self.order]
        self.uk, self.start, self.count = np.unique(kk, return_index=True, return_counts=True)

    def knn(self, q, k, rings):
        """k nearest within the (2*rings+1)^3 cells around each query: (dist, idx), -1 when none."""
        cq = np.floor(q / self.c).astype(np.int64)
        best_d = np.full((len(q), k), np.inf); best_i = np.full((len(q), k), -1)
        r = range(-rings, rings + 1)
        for dx in r:
            for dy in r:
                for dz in r:
                    kq = self.key(cq + np.array([dx, dy, dz]))
                    loc = np.clip(np.searchsorted(self.uk, kq), 0, len(self.uk) - 1)
                    hit = self.uk[loc] == kq
                    s = np.where(hit, self.start[loc], 0); c = np.where(hit, self.count[loc], 0)
                    for j in range(int(c.max()) if len(c) else 0):
                        qi = np.nonzero(c > j)[0]; pi = self.order[s[qi] + j]
                        d = np.linalg.norm(q[qi] - self.p[pi], axis=1)
                        cand_d = np.concatenate([best_d[qi], d[:, None]], 1)
                        cand_i = np.concatenate([best_i[qi], pi[:, None]], 1)
                        o = np.argsort(cand_d, 1)[:, :k]
                        best_d[qi] = np.take_along_axis(cand_d, o, 1); best_i[qi] = np.take_along_axis(cand_i, o, 1)
        return best_d, best_i


def sample_nodes(pts, wanted):
    lo, hi = pts.min(0), pts.max(0)
    cell = np.linalg.norm(hi - lo) / np.cbrt(wanted) * 0.6
    for _ in range(12):
        k = np.floor((pts - lo) / cell).astype(np.int64)
        _, first = np.unique(k, axis=0, return_index=True)
        ratio = len(first) / wanted
        if 0.75 < ratio < 1.4: break
        cell *= np.cbrt(ratio)
    return np.sort(first)


def nearest_rotation(m):
    u, _, vt = np.linalg.svd(m)
    r = u @ vt
    bad = np.linalg.det(r) < 0
    u[bad, :, 2] *= -1
    r[bad] = u[bad] @ vt[bad]
    return r


def rot_to_quat(r):
    w = np.sqrt(np.maximum(0, 1 + r[:, 0, 0] + r[:, 1, 1] + r[:, 2, 2])) / 2
    w = np.maximum(w, 1e-8)
    return np.stack([w, (r[:, 2, 1] - r[:, 1, 2]) / (4 * w), (r[:, 0, 2] - r[:, 2, 0]) / (4 * w),
                     (r[:, 1, 0] - r[:, 0, 1]) / (4 * w)], 1)


def warp(source, target):
    g = source[sample_nodes(source, NODES)]
    N = len(g)
    ng = Grid(g, 0.05)
    d2, i2 = ng.knn(g[::max(1, N // 512)], 2, 10)
    spacing = float(np.mean(d2[:, 1][np.isfinite(d2[:, 1])]))
    bind = spacing * 3.0
    ng = Grid(g, spacing)
    dn, nb = ng.knn(g, NODE_NB + 1, int(np.ceil(bind * 2 / spacing)))
    nb = nb[:, 1:]; valid = (nb >= 0) & np.isfinite(dn[:, 1:]) & (dn[:, 1:] < bind * 2)
    nb = np.where(valid, nb, np.arange(N)[:, None])
    tg = Grid(target, spacing)
    rings = int(np.ceil(MAX_CORR / spacing))
    R = np.tile(np.eye(3), (N, 1, 1)); t = np.zeros((N, 3))
    e0 = g[nb] - g[:, None, :]                      # [N, K, 3]
    deg = valid.sum(1)
    w = np.where(deg > 0, ARAP / np.maximum(deg, 1), 0.0)
    def rms():
        d, j = tg.knn(g + t, 1, rings); ok = j[:, 0] >= 0
        return np.sqrt(np.mean(d[ok, 0] ** 2)) * 1000
    before = rms()
    for _ in range(OUTER):
        d, j = tg.knn(g + t, 1, rings); has = (j[:, 0] >= 0) & (d[:, 0] < MAX_CORR)
        corr = np.where(has[:, None], target[np.maximum(j[:, 0], 0)], g)
        e1 = (g[nb] + t[nb]) - (g + t)[:, None, :]
        S = np.einsum("nki,nkj->nij", e1 * valid[..., None], e0)
        R = np.where((deg > 0)[:, None, None], nearest_rotation(S), R)
        for _ in range(SWEEPS):  # Jacobi on the quadratic translation step
            rhs = np.where(has[:, None], corr - g, 0.0)
            diag = has.astype(float)
            a = (g[nb] + t[nb] - g[:, None, :]) - np.einsum("nij,nkj->nki", R, e0)
            b = (g[nb] + t[nb] - g[:, None, :]) + np.einsum("nkij,nkj->nki", R[nb], -e0)
            rhs = rhs + w[:, None] * ((a + b) * valid[..., None]).sum(1)
            diag = diag + 2 * w * deg
            t = np.where((diag > 0)[:, None], rhs / np.maximum(diag, 1e-12)[:, None], t)
    return g, t, rot_to_quat(R), bind, before, rms()


if __name__ == "__main__":
    first, last, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    os.makedirs(out, exist_ok=True)
    prev = cloud(first)
    for f in range(first + 1, last + 1):
        cur = cloud(f)
        g, t, q, bind, b, a = warp(prev, cur)
        rows = np.concatenate([g, t, q], 1).astype(np.float32)
        with open(f"{out}/{f - first:03d}.bin", "wb") as fh:
            fh.write(struct.pack("<if", len(g), bind)); fh.write(rows.tobytes())
        print(f"{f-1}->{f}: {len(g)} nodes, bind {bind*1000:.1f} mm, RMS {b:.1f} -> {a:.1f} mm, "
              f"mean |t| {np.linalg.norm(t, axis=1).mean()*1000:.1f} mm", flush=True)
        prev = cur
