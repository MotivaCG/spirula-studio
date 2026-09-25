"""Stability and fit of splat sequences on VIDEOTIKI 45-50: Gracia, Forge's chain, chunk runs.

python evaluate.py [run ...]      runs are folders under outputs/tc with frames/NNN/splat.ply
"""
import glob, json, os, subprocess, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROBE = r"C:/Users/Victor/AppData/Local/Temp/claude/D--Trabajos-FORMS-LichtFeld-Studio/94f3fca3-18b7-436e-85cc-dace05fd9989/scratchpad/mint/probe"
sys.path.insert(0, PROBE); sys.path.insert(0, HERE)
import flicker_lib as fl
import hull

WORK = "C:/Users/Victor/Documents/Gracia4DGSConverter/VIDEOTIKI/output/.work"
FRAMES = list(range(45, 51))


def set_frames(first, last):
    global FRAMES
    FRAMES[:] = list(range(first, last + 1))
frame_dir = lambda f: f"{WORK}/000000{f}/undistorted"
LUMA = fl.LUMA


def load_subject(ply, f):
    F = fl.ply_frame(ply)
    keep = hull.subject(F["pos"], frame_dir(f))
    return F, keep


def subset(F, keep):
    return {k: v[keep] for k, v in F.items()}


def stability(frames, identity):
    """frames: list of (F, keep). Voxel metrics on the kept subject; per-splat on common rows."""
    sub = [subset(F, k) for F, k in frames]
    for i, S in enumerate(sub):
        S["ids"] = np.array([-1 - i])  # per-splat metrics are computed below, not in fl
    h = np.median([fl.height(S) for S in sub]); cell = h / 64
    rows = []
    for i in range(len(sub) - 1):
        r = fl.pair_metrics(sub[i], sub[i + 1], cell)
        (A, ka), (B, kb) = frames[i], frames[i + 1]
        if identity and len(ka) == len(kb):  # Gracia renumbers at its chunk boundaries
            v = ka & kb & (A["opa"] > 0.1)
            r["id_dpos"] = np.median(np.linalg.norm(A["pos"][v] - B["pos"][v], axis=1)) / h
            r["id_dL"] = np.median(np.abs((A["col"][v] - B["col"][v]) @ LUMA))
            r["id_dopa"] = np.median(np.abs(A["opa"][v] - B["opa"][v]))
            r["id_dlogS"] = np.median(np.abs(np.log(A["scl"][v] / B["scl"][v])).max(1))
        rows.append(r)
    return {k: float(np.mean([r[k] for r in rows if k in r])) for k in set().union(*rows)}


def fit_quality(ply, f, name):
    """Masked, colour-corrected PSNR over every 8th (trained) camera."""
    qdir = f"{HERE}/q/{name}"
    if not os.path.exists(f"{qdir}/eval_views.txt"):
        subprocess.run(["powershell", "-NoProfile", "-File", f"{HERE}/evalply.ps1", ply, str(f), name],
                       check=True, capture_output=True)
    pairs = [l.split("\t") for l in open(f"{qdir}/eval_views.txt").read().splitlines()]
    thumb = lambda im: np.asarray(im.convert("RGB").resize((32, 56)), np.float32)
    thumbs = np.stack([thumb(Image.open(img)) for img, _ in pairs])
    ps = []
    for i in range(len(pairs)):
        gi = Image.open(f"{qdir}/eval-gt-{i:05d}.png")
        gt = np.asarray(gi, np.float32) / 255
        rd = np.asarray(Image.open(f"{qdir}/eval-render-{i:05d}.png"), np.float32) / 255
        # The eval loader shuffles: view i is found by content, not position.
        k = int(np.argmin(((thumbs - thumb(gi)) ** 2).sum((1, 2, 3))))
        m = np.asarray(Image.open(pairs[k][1]).convert("L").resize(gt.shape[1::-1])) > 127
        g, r = gt[m], rd[m]
        fit = np.empty_like(r)
        for c in range(3):
            A = np.stack([r[:, c], np.ones(len(r))], 1)
            fit[:, c] = A @ np.linalg.lstsq(A, g[:, c], rcond=None)[0]
        ps.append(10 * np.log10(1 / max(np.mean((g - fit) ** 2), 1e-10)))
    return float(np.mean(ps))


def box_blur(x, r=3):
    """Separable box blur of an HxWxC image, radius r px, edges clamped."""
    for axis in (0, 1):
        pad = [(0, 0)] * x.ndim; pad[axis] = (r + 1, r)
        c = np.cumsum(np.pad(x, pad, mode="edge"), axis=axis)
        n = x.shape[axis]
        x = (np.take(c, range(2 * r + 1, 2 * r + 1 + n), axis=axis) -
             np.take(c, range(0, n), axis=axis)) / (2 * r + 1)
    return x


def detail_quality(name):
    """Masked PSNR of the high frequencies (image minus a 7 px box blur), after the
    same per-channel colour map as fit_quality: what a loss of detail lowers."""
    qdir = f"{HERE}/q/{name}"
    pairs = [l.split("\t") for l in open(f"{qdir}/eval_views.txt").read().splitlines()]
    thumb = lambda im: np.asarray(im.convert("RGB").resize((32, 56)), np.float32)
    thumbs = np.stack([thumb(Image.open(img)) for img, _ in pairs])
    ps = []
    for i in range(len(pairs)):
        gi = Image.open(f"{qdir}/eval-gt-{i:05d}.png")
        gt = np.asarray(gi, np.float32) / 255
        rd = np.asarray(Image.open(f"{qdir}/eval-render-{i:05d}.png"), np.float32) / 255
        k = int(np.argmin(((thumbs - thumb(gi)) ** 2).sum((1, 2, 3))))
        m = np.asarray(Image.open(pairs[k][1]).convert("L").resize(gt.shape[1::-1])) > 127
        for c in range(3):
            A = np.stack([rd[..., c][m], np.ones(int(m.sum()))], 1)
            a, b = np.linalg.lstsq(A, gt[..., c][m], rcond=None)[0]
            rd[..., c] = rd[..., c] * a + b
        hg, hr = gt - box_blur(gt), rd - box_blur(rd)
        ps.append(10 * np.log10(1 / max(np.mean((hg - hr)[m] ** 2), 1e-12)))
    return float(np.mean(ps))


def camera_views(qdir):
    """eval index -> (camera name, source image, mask), matched by content."""
    pairs = [l.split("\t") for l in open(f"{qdir}/eval_views.txt").read().splitlines()]
    thumb = lambda im: np.asarray(im.convert("RGB").resize((32, 56)), np.float32)
    thumbs = np.stack([thumb(Image.open(img)) for img, _ in pairs])
    out = {}
    for i in range(len(pairs)):
        k = int(np.argmin(((thumbs - thumb(Image.open(f"{qdir}/eval-gt-{i:05d}.png"))) ** 2).sum((1, 2, 3))))
        name = os.path.splitext(os.path.basename(pairs[k][0].replace("\\", "/")))[0]
        out[name] = (i, pairs[k][1])
    return out


def blocks(x, b=16):
    h, w = (x.shape[0] // b) * b, (x.shape[1] // b) * b
    return x[:h, :w].reshape(h // b, b, w // b, b, -1).mean((1, 3))


def render_flicker(tag):
    """Per fixed camera: |d render - d video| between consecutive frames, inside the mask.

    Real motion cancels; what is left is change the render adds (flicker, jitter) or
    misses (motion it failed to follow). One colour map per camera, shared by all frames.
    """
    qdirs = [f"{HERE}/q/{tag}_{f}" for f in FRAMES]
    views = [camera_views(q) for q in qdirs]
    # The eval loader samples with replacement, so a camera can miss a frame: pairs
    # use the cameras both of their frames have.
    cams = sorted(set.union(*[set(v) for v in views]))
    load = lambda p: np.asarray(Image.open(p), np.float32) / 255
    err, dr, dg, lerr, pair = [], [], [], [], {}
    for cam in cams:
        have = [cam in v for v in views]
        R = [load(f"{q}/eval-render-{v[cam][0]:05d}.png") if h else None for q, v, h in zip(qdirs, views, have)]
        G = [load(f"{q}/eval-gt-{v[cam][0]:05d}.png") if h else None for q, v, h in zip(qdirs, views, have)]
        shape = next(g for g in G if g is not None).shape
        M = [np.asarray(Image.open(v[cam][1]).convert("L").resize(shape[1::-1])) > 127 if h else None
             for v, h in zip(views, have)]
        ok_t = [t for t in range(len(R)) if have[t]]
        allm = np.concatenate([R[t][M[t]] for t in ok_t]); allg = np.concatenate([G[t][M[t]] for t in ok_t])
        coef = [np.linalg.lstsq(np.stack([allm[:, c], np.ones(len(allm))], 1), allg[:, c], rcond=None)[0]
                for c in range(3)]
        R = [np.stack([r[..., c] * coef[c][0] + coef[c][1] for c in range(3)], -1) if r is not None else None
             for r in R]
        for t in range(len(R) - 1):
            if not (have[t] and have[t + 1]):
                continue
            m = M[t] | M[t + 1]
            d_r = (R[t + 1] - R[t])[m]; d_g = (G[t + 1] - G[t])[m]
            err.append(np.abs(d_r - d_g).mean()); dr.append(np.abs(d_r).mean()); dg.append(np.abs(d_g).mean())
            # Regional: 16 px block means inside the mask, where sensor noise averages out.
            w = blocks(m[..., None].astype(np.float32))[..., 0]
            ok = w > 0.5
            br = [blocks(x * m[..., None]) / np.maximum(w[..., None], 1e-6) for x in (R[t], R[t + 1])]
            bg = [blocks(x * m[..., None]) / np.maximum(w[..., None], 1e-6) for x in (G[t], G[t + 1])]
            lerr.append(np.abs((br[1] - br[0]) - (bg[1] - bg[0]))[ok].mean())
            pair.setdefault(t, []).append(lerr[-1])
    per_pair = [float(np.mean(pair[t])) for t in sorted(pair)]
    return float(np.mean(err)), float(np.mean(dr)), float(np.mean(dg)), float(np.mean(lerr)), per_pair


MINT = "d:/Trabajos/ScanMeNow/SMNWebviewer/Playcanvas/public/data/tiki.mint"


def gracia_dump(f):
    """tiki.mint at frame f (t = f / 30 s), with SH, dumped by the probe on first use."""
    path = f"{PROBE}/tksh/f_{f / 30 + 1e-4:.4f}.bin"
    if not os.path.exists(path):
        env = dict(os.environ, PATH="C:/Qt/Qt6.8.1/6.8.0/msvc2022_64/bin;" + os.environ["PATH"])
        subprocess.run([f"{PROBE}/release/mintprobe.exe", MINT, f"{PROBE}/tksh/f", f"{f / 30 + 1e-4:.4f}"],
                       check=True, capture_output=True, env=env)
    return path


def mint_all(path):
    """A Gracia dump with every chunk record, and which are alive at that instant."""
    raw = open(path, "rb").read()
    n = int(np.frombuffer(raw[:8], np.uint64)[0]); o = 8; F = {}
    for name, k in [("pos", 3), ("scl", 3), ("opa", 1), ("col", 3), ("rot", 4)]:
        a = np.frombuffer(raw[o:o + 4 * n * k], np.float32); o += 4 * n * k
        F[name] = a.reshape(n, k) if k > 1 else a
    return F, np.frombuffer(raw[o:o + n], np.uint8).astype(bool)


def forge_plys():
    return [sorted(glob.glob(f"{frame_dir(f)}/smn/step-*.ckpt/splat.ply"))[-1] for f in FRAMES]


def run_plys(run):
    """A run, a chain "a,b,c" whose later chunks start on the previous chunk's last frame,
    or a <prefix>.seq file mapping every frame to its run and index."""
    if run.endswith(".seq"):
        rows = {int(f): (r, int(i)) for f, r, i in (l.split() for l in open(f"{HERE}/{run}"))}
        return [f"{HERE}/{rows[f][0]}/frames/{rows[f][1]:03d}/splat.ply" for f in FRAMES]
    plys = []
    for i, r in enumerate(run.split(",")):
        n = len(glob.glob(f"{HERE}/{r}/frames/[0-9][0-9][0-9]"))
        plys += [f"{HERE}/{r}/frames/{k:03d}/splat.ply" for k in range(1 if i else 0, n)]
    return plys[:len(FRAMES)]


def line(label, s, q=None, rf=None):
    txt = (f"{label:22s} voxel dL p50={s['dL50']:.4f} p90={s['dL90']:.4f} | mass p50={s['dM50']*100:5.1f}% "
           f"p90={s['dM90']*100:5.1f}%")
    if "id_dpos" in s:
        txt += (f" | splat dpos={s['id_dpos']*1000:.2f}permilleH dL={s['id_dL']:.4f} "
                f"dopa={s['id_dopa']:.4f} dlogS={s['id_dlogS']:.4f}")
    if q is not None:
        txt += f" | fit mccPSNR={np.mean(q):.2f} [{min(q):.2f}..{max(q):.2f}]"
    if rf is not None:
        txt += (f" | RENDER px={rf[0]*1000:.2f}e-3 (render {rf[1]*1000:.1f} video {rf[2]*1000:.1f})"
                f" REGIONAL={rf[3]*1000:.2f}e-3")
        if PER_PAIR:
            txt += "\n      per pair: " + " ".join(f"{FRAMES[t]}>{FRAMES[t]+1}:{v*1000:.1f}" for t, v in enumerate(rf[4]))
    print(txt, flush=True)


def evaluate(label, plys, identity, tag):
    frames = [load_subject(p, f) for p, f in zip(plys, FRAMES)]
    q = [fit_quality(p, f, f"{tag}_{f}") for p, f in zip(plys, FRAMES)]
    line(label, stability(frames, identity), q, render_flicker(tag))


PER_PAIR = False

if __name__ == "__main__":
    args = sys.argv[1:]
    if args and ":" in args[0] and args[0][0].isdigit():
        a, b = args.pop(0).split(":"); set_frames(int(a), int(b))
    if "--pairs" in args:
        args.remove("--pairs"); PER_PAIR = True
    sys.argv = [sys.argv[0]] + args
    for f in FRAMES:
        if not os.path.exists(f"{HERE}/q/gracia_{f}/eval_views.txt"):
            subprocess.run([sys.executable, f"{HERE}/gracia_assets.py", str(f)], check=True)
            subprocess.run(["powershell", "-NoProfile", "-File", f"{HERE}/evalgracia.ps1", str(f)], check=True,
                           capture_output=True)
    q = [fit_quality(None, f, f"gracia_{f}") for f in FRAMES]
    line("GRACIA tiki", stability([mint_all(gracia_dump(f)) for f in FRAMES], identity=True), q,
         render_flicker("gracia"))
    evaluate("Forge chain", forge_plys(), identity=False, tag="forge")
    for run in sys.argv[1:]:
        evaluate(run, run_plys(run), identity=True, tag=run)
