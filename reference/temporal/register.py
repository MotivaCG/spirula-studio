"""Similarity transform taking Gracia's tiki frame into our COLMAP frame, by scaled ICP."""
import itertools, json, sys
import numpy as np
sys.path.insert(0, "."); import evaluate as e

def load_mint(path):
    F, act = e.mint_all(path); m = act & (F["opa"] > 0.3); return F["pos"][m]

def nearest(a, b):
    # Brute force in blocks: both clouds are subsampled to a few thousand points.
    d = np.empty(len(a)); j = np.empty(len(a), int)
    for s in range(0, len(a), 2048):
        dd = ((a[s:s+2048, None, :] - b[None]) ** 2).sum(-1)
        j[s:s+2048] = dd.argmin(1); d[s:s+2048] = np.sqrt(dd.min(1))
    return d, j

def umeyama(src, dst):
    ms, md = src.mean(0), dst.mean(0); a, b = src - ms, dst - md
    U, S, Vt = np.linalg.svd(b.T @ a / len(src))
    D = np.eye(3); D[2, 2] = np.sign(np.linalg.det(U @ Vt))
    R = U @ D @ Vt; s = np.trace(np.diag(S) @ D) / (a ** 2).sum(1).mean()
    return s, R, md - s * R @ ms

if __name__ == "__main__":
    rng = np.random.default_rng(0)
    G = load_mint(f"{e.PROBE}/tksh/f_1.5001.bin")
    Fo = e.fl.ply_frame(e.forge_plys()[0]); k = e.hull.subject(Fo["pos"], e.frame_dir(45)) & (Fo["opa"] > 0.3)
    O = Fo["pos"][k]
    g = G[rng.choice(len(G), 4000, replace=False)]; o = O[rng.choice(len(O), 6000, replace=False)]
    rms = lambda x: np.sqrt(((x - x.mean(0)) ** 2).sum(1).mean())
    best = None
    for perm in itertools.permutations(range(3)):
        for signs in itertools.product([1, -1], repeat=3):
            R0 = np.zeros((3, 3))
            for r, (c, sg) in enumerate(zip(perm, signs)): R0[r, c] = sg
            if np.linalg.det(R0) < 0: continue
            s = rms(o) / rms(g); R = R0; t = o.mean(0) - s * R @ g.mean(0)
            for it in range(40):
                x = s * g @ R.T + t
                d, j = nearest(x, o)
                keep = d < np.percentile(d, 80)
                s, R, t = umeyama(g[keep], o[j[keep]])
            d, _ = nearest(s * g @ R.T + t, o)
            err = np.median(d)
            if best is None or err < best[0]: best = (err, s, R, t)
    err, s, R, t = best
    print(f"median residual {err*1000:.1f} mm, scale {s:.4f}")
    print("R", np.round(R, 4).tolist()); print("t", np.round(t, 4).tolist())
    json.dump({"s": s, "R": R.tolist(), "t": t.tolist(), "median_residual": err}, open("gracia_to_colmap.json", "w"), indent=1)
