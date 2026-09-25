"""Frame-to-frame instability of a splat sequence: Gracia .mint dumps vs spirula PLYs."""
import os, sys, warnings
import numpy as np
warnings.filterwarnings("ignore")
C0 = 0.28209479177387814
LUMA = np.array([0.2126, 0.7152, 0.0722], np.float32)
TAKE = "C:/Users/Victor/Documents/Gracia4DGSConverter/VIDEOTIKI"

def mint_frame(path):
    raw = open(path, "rb").read()
    n = int(np.frombuffer(raw[:8], np.uint64)[0]); o = 8; f = {}
    for name, k in [("pos", 3), ("scl", 3), ("opa", 1), ("col", 3), ("rot", 4)]:
        a = np.frombuffer(raw[o:o + 4 * n * k], np.float32); o += 4 * n * k
        f[name] = a.reshape(n, k) if k > 1 else a
    act = np.frombuffer(raw[o:o + n], np.uint8).astype(bool)
    return {k: v[act] for k, v in f.items()} | {"ids": np.nonzero(act)[0]}

def ply_frame(path):
    raw = open(path, "rb").read()
    end = raw.find(b"end_header\n") + len(b"end_header\n")
    head = raw[:end].decode("ascii").splitlines()
    n = int([l for l in head if l.startswith("element vertex")][0].split()[-1])
    props = [l.split()[-1] for l in head if l.startswith("property")]
    a = np.frombuffer(raw[end:end + 4 * n * len(props)], np.float32).reshape(n, len(props))
    col = lambda c: a[:, props.index(c)]
    dc = np.stack([col("f_dc_0"), col("f_dc_1"), col("f_dc_2")], 1)
    return {"pos": np.stack([col("x"), col("y"), col("z")], 1),
            "scl": np.exp(np.stack([col("scale_0"), col("scale_1"), col("scale_2")], 1)),
            "opa": 1 / (1 + np.exp(-col("opacity"))),
            "col": 0.5 + C0 * dc, "ids": np.arange(n)}

def height(F):
    m = F["opa"] > 0.3; p = F["pos"][m]
    ext = np.percentile(p, 99, 0) - np.percentile(p, 1, 0)
    return ext.max()

def voxels(F, cell):
    m = F["opa"] > 0.02
    key = np.floor(F["pos"][m] / cell).astype(np.int64)
    k = (key[:, 0] + 2**20) * 2**42 + (key[:, 1] + 2**20) * 2**21 + (key[:, 2] + 2**20)
    w = F["opa"][m]; L = F["col"][m] @ LUMA
    uk, inv = np.unique(k, return_inverse=True)
    mass = np.bincount(inv, w); lum = np.bincount(inv, w * L) / mass
    return dict(zip(uk.tolist(), zip(mass, lum))), mass

def pair_metrics(A, B, cell):
    VA, ma = voxels(A, cell); VB, _ = voxels(B, cell)
    floor = np.percentile(ma, 50) * 0.5
    common = [k for k in VA if k in VB and VA[k][0] > floor and VB[k][0] > floor]
    mA = np.array([VA[k][0] for k in common]); mB = np.array([VB[k][0] for k in common])
    lA = np.array([VA[k][1] for k in common]); lB = np.array([VB[k][1] for k in common])
    w = (mA + mB) / 2
    dl = np.abs(lA - lB); dm = np.abs(mA - mB) / w
    wq = lambda x, q: np.interp(q, np.cumsum(w[np.argsort(x)]) / w.sum(), np.sort(x))
    out = {"dL50": wq(dl, .5), "dL90": wq(dl, .9), "dM50": wq(dm, .5), "dM90": wq(dm, .9)}
    if len(A["ids"]) == len(B["ids"]) and np.array_equal(A["ids"], B["ids"]):
        v = A["opa"] > 0.1
        out["id_dpos50"] = np.median(np.linalg.norm(A["pos"][v] - B["pos"][v], axis=1)) / height(A)
        out["id_dL50"] = np.median(np.abs((A["col"][v] - B["col"][v]) @ LUMA))
        out["id_dopa50"] = np.median(np.abs(A["opa"][v] - B["opa"][v]))
        out["id_dscl50"] = np.median(np.abs(np.log(A["scl"][v] / B["scl"][v])).max(1))
    return out

def report(label, frames, extra=""):
    h = np.median([height(F) for F in frames]); cell = h / 64
    rows = [pair_metrics(frames[i], frames[i + 1], cell) for i in range(len(frames) - 1)]
    mean = {k: np.mean([r[k] for r in rows if k in r]) for k in rows[0]}
    Lmean = np.mean([np.average(F["col"] @ LUMA, weights=F["opa"]) for F in frames])
    s = (f"{label:26s} n={len(frames):2d} splats~{int(np.median([len(F['opa']) for F in frames])):7d} "
         f"meanL={Lmean:.3f} | voxel dL p50={mean['dL50']:.4f} p90={mean['dL90']:.4f} "
         f"| mass change p50={mean['dM50']*100:5.1f}% p90={mean['dM90']*100:5.1f}%")
    if "id_dpos50" in mean:
        s += (f" | per-splat dpos={mean['id_dpos50']*1000:.2f}‰H dL={mean['id_dL50']:.4f} "
              f"dopa={mean['id_dopa50']:.4f} dlogS={mean['id_dscl50']:.4f}")
    print(s + extra, flush=True)

