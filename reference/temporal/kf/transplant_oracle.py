"""Phase 0 of POPULATION_BUILDER_4D.md: transplant oracle, no training.
Per frame: where ST7L misses detail (high-pass error vs the video, confirmed by >= 3 other cameras
through the render's depth), swap ST7L's records there for NAIF's splats. Then: how many
transplanted splats find a partner 1/4/8 frames on (moved by ST7L's neighbours), and two PLY
sequences for vgsplyseq: every transplant its own 1-frame record (TPO_A), and NAIF of every 8th
frame carried 8 frames by ST7L's motion (TPO_K).
Usage (ref4d venv, -I): transplant_oracle.py"""
import os, sys
sys.path[:0] = [os.path.dirname(os.path.abspath(__file__))]
import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
from gsplat.rendering import rasterization
import ho_lib as H

TC = "D:/Dependencias/spirula-studio/outputs/tc"
NAIF = "C:/Users/Victor/Documents/Gracia4DGSConverter/VIDEOTIKI/output/{:08d}.ply"
FIRST, FRAMES = 45, list(range(51, 77))  # NAIF of the current recipe covers 51-76
if os.environ.get("TPO_FRAMES"):  # dry runs: a few consecutive frames, no sequences written
    FRAMES = list(range(*map(int, os.environ["TPO_FRAMES"].split("-"))))
DOWN = 2            # error maps at half resolution
VOX = 0.01          # confirmed-region voxel (m) and transplant radius
DTOL = 0.02         # depth agreement for visibility in another camera (m)
VOTES = 3
dev = "cuda"
t = lambda a: torch.as_tensor(np.asarray(a), dtype=torch.float32, device=dev)
LUM = t([0.299, 0.587, 0.114])
C0 = 0.28209479177387814
os.makedirs(f"{TC}/TPO_work", exist_ok=True)


def load(path):
    head, rows, props = H.read_ply(path)
    c = {p: i for i, p in enumerate(props)}
    return head, rows, c


def splats(rows, c):
    g = lambda *ks: rows[:, [c[k] for k in ks]]
    rest = sorted((p for p in c if p.startswith("f_rest_")), key=lambda p: int(p[7:]))
    nb = len(rest) // 3
    sh = np.concatenate([g("f_dc_0", "f_dc_1", "f_dc_2")[:, None], g(*rest).reshape(-1, 3, nb).transpose(0, 2, 1)], 1)
    return dict(pos=t(g("x", "y", "z")), q=F.normalize(t(g("rot_0", "rot_1", "rot_2", "rot_3")), dim=1),
                sc=torch.exp(t(g("scale_0", "scale_1", "scale_2"))), op=torch.sigmoid(t(rows[:, c["opacity"]])),
                sh=t(sh), deg=int(round(np.sqrt(nb + 1))) - 1)


def cam(f, name, down):
    cams, imgs = cam.cache.setdefault(f, (H.read_cameras(f"{H.frame_dir(f)}/sparse/cameras.bin"),
                                          H.read_images(f"{H.frame_dir(f)}/sparse/images.bin")))
    qv, tv, cid, _ = imgs[name]
    _, W, Hh, p = cams[cid]
    K = np.array([[p[0], 0, p[2]], [0, p[1], p[3]], [0, 0, 1]], np.float64)
    K[:2] /= down
    return H.qrot(qv), np.asarray(tv), K, W // down, Hh // down
cam.cache = {}


def render(s, R, T, K, W, Hh):
    vm = torch.eye(4, device=dev); vm[:3, :3] = t(R); vm[:3, 3] = t(T)
    out, alpha, _ = rasterization(s["pos"], s["q"], s["sc"], s["op"], s["sh"], vm[None], t(K)[None], W, Hh,
                                  sh_degree=s["deg"], render_mode="RGB+ED")
    return out[0, ..., :3].clamp(0, 1), out[0, ..., 3], alpha[0, ..., 0]


def blur(x, sigma):
    r = int(3 * sigma); k = torch.exp(-torch.arange(-r, r + 1, device=dev) ** 2 / (2 * sigma * sigma)); k = k / k.sum()
    x = F.conv2d(x[None, None], k[None, None, None], padding=(0, r))
    return F.conv2d(x, k[None, None, :, None], padding=(r, 0))[0, 0]


def error_map(r, v, m, a):
    """Detail error: smoothed |HP(render) - HP(video)| above half the video's local detail, in
    textured parts of the mask where the render is opaque. Colour matched per channel first."""
    x = r[m]; y = v[m]; rr = r.clone()
    for ch in range(3):
        A = torch.stack([x[:, ch], torch.ones_like(x[:, ch])], 1)
        sol = torch.linalg.lstsq(A, y[:, ch:ch + 1]).solution[:, 0]
        rr[..., ch] = r[..., ch] * sol[0] + sol[1]
    hp = lambda img: blur(img @ LUM, 1.0) - blur(img @ LUM, 4.0)
    err, tex = blur((hp(rr) - hp(v)).abs(), 3.0), blur(hp(v).abs(), 3.0)
    return m & (a > 0.5) & (tex > tex[m].median()) & (err > 0.5 * tex)


def confirmed_voxels(f, st):
    names = H.names(f)
    views = []
    for name in names:
        R, T, K, W, Hh = cam(f, name, DOWN)
        v = t(np.asarray(Image.open(f"{H.frame_dir(f)}/images/{name}.png").convert("RGB").resize((W, Hh), Image.BILINEAR), np.float32) / 255)
        m = torch.from_numpy(H.mask(f, name, down=DOWN, dilate=-0.01)).to(dev)
        r, d, a = render(st, R, T, K, W, Hh)
        views.append((R, T, K, W, Hh, error_map(r, v, m, a), d, a, m))
    flagged = sum(float(e.sum()) for *_, e, d, a, m in views) / max(sum(float(m.sum()) for *_, m in views), 1)
    keys = []
    for i, (R, T, K, W, Hh, E, d, a, m) in enumerate(views):
        ys, xs = torch.nonzero(E[::2, ::2], as_tuple=True); ys, xs = ys * 2, xs * 2
        if len(ys) == 0: continue
        z = d[ys, xs]
        xc = torch.stack([(xs + 0.5 - K[0, 2]) / K[0, 0] * z, (ys + 0.5 - K[1, 2]) / K[1, 1] * z, z], 1)
        X = (xc - t(T)) @ t(R)  # R^T (xc - T)
        votes, seen = torch.zeros(len(X), device=dev), torch.zeros(len(X), device=dev)
        for j, (R2, T2, K2, W2, H2, E2, d2, a2, m2) in enumerate(views):
            if j == i: continue
            x2 = X @ t(R2).T + t(T2)
            u = (K2[0, 0] * x2[:, 0] / x2[:, 2] + K2[0, 2]).floor().long()
            w = (K2[1, 1] * x2[:, 1] / x2[:, 2] + K2[1, 2]).floor().long()
            ok = (x2[:, 2] > 0.05) & (u >= 0) & (u < W2) & (w >= 0) & (w < H2)
            uu, ww = u.clamp(0, W2 - 1), w.clamp(0, H2 - 1)
            vis = ok & (a2[ww, uu] > 0.5) & ((d2[ww, uu] - x2[:, 2]).abs() < DTOL)
            votes += (vis & E2[ww, uu]).float(); seen += vis.float()
        # With ~40 cameras seeing a point, 3 chance votes are common: also half of those that see it.
        keep = X[(votes >= VOTES) & (votes >= 0.5 * seen)]
        keys.append(torch.unique(torch.floor(keep / VOX).long(), dim=0))
    vox = torch.unique(torch.cat(keys), dim=0) if keys else torch.zeros((0, 3), dtype=torch.long, device=dev)
    return vox, flagged


def near(points, vox):
    """Points within one voxel ring of a confirmed voxel."""
    if len(vox) == 0: return torch.zeros(len(points), dtype=torch.bool, device=dev)
    code = lambda k: (k[:, 0] + 2 ** 20) * 2 ** 42 + (k[:, 1] + 2 ** 20) * 2 ** 21 + (k[:, 2] + 2 ** 20)
    table = torch.sort(code(vox)).values
    base = torch.floor(points / VOX).long()
    hit = torch.zeros(len(points), dtype=torch.bool, device=dev)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                c = code(base + torch.tensor([dx, dy, dz], device=dev))
                i = torch.searchsorted(table, c).clamp(max=len(table) - 1)
                hit |= table[i] == c
    return hit


def nn_search(q, p, chunk=4096):
    """Nearest p for every q: (index, distance)."""
    idx, dist = [], []
    for s in range(0, len(q), chunk):
        d = torch.cdist(q[s:s + chunk], p)
        v, i = d.min(1); idx.append(i); dist.append(v)
    return torch.cat(idx), torch.cat(dist)


# --- 1. per frame: confirmed regions, removed ST7L rows, transplanted NAIF splats -----------
head_st, rows0, cst = load(f"{TC}/ST7L_clean/frames/000/splat.ply")
NST = len(rows0)
plan = {}
for f in FRAMES:
    _, rst, _ = load(f"{TC}/ST7L_clean/frames/{f - FIRST:03d}/splat.ply")
    _, rnf, cnf = load(NAIF.format(f))
    st, nf = splats(rst, cst), splats(rnf, cnf)
    vox, flagged = confirmed_voxels(f, st)
    shown = st["op"] > 1 / 255
    remove = (near(st["pos"], vox) & shown).cpu().numpy()
    add = (near(nf["pos"], vox) & (nf["op"] > 1 / 255)).cpu().numpy()
    plan[f] = (remove, np.nonzero(add)[0], rnf)
    print(f"frame {f}: error pixels {flagged * 100:.1f} % of mask, confirmed voxels {len(vox)}, "
          f"ST7L rows removed {remove.sum()} of {int(shown.sum())} shown, NAIF splats in {len(np.nonzero(add)[0])} of {len(rnf)}", flush=True)

# --- 2. ST7L's motion, and whether transplants of f find a partner among f+1's ---------------
_ply = {}
def st7l(f):
    if f not in _ply: _ply[f] = load(f"{TC}/ST7L_clean/frames/{f - FIRST:03d}/splat.ply")[1]
    return _ply[f]

def advect(p, f):
    """Points moved f -> f+1 by the mean step of their 8 nearest ST7L records (shown in both)
    within 2 cm, the nearest one when none is that close."""
    s0, s1 = st7l(f), st7l(f + 1)
    both = (1 / (1 + np.exp(-s0[:, cst["opacity"]])) > 0.1) & (1 / (1 + np.exp(-s1[:, cst["opacity"]])) > 0.1)
    A0, A1 = t(s0[both][:, [cst["x"], cst["y"], cst["z"]]]), t(s1[both][:, [cst["x"], cst["y"], cst["z"]]])
    out = []
    for s in range(0, len(p), 2048):
        v, k = torch.cdist(p[s:s + 2048], A0).topk(8, largest=False)
        w = torch.where(v < 0.02, 1 / (v + 1e-3), torch.zeros_like(v)); w[:, 0] = torch.where(w.sum(1) > 0, w[:, 0], torch.ones_like(w[:, 0]))
        out.append(((A1[k] - A0[k]) * w[..., None]).sum(1) / w.sum(1, keepdim=True))
    return p + torch.cat(out) if out else p

def attrs(rows, c, idx):
    r = rows[idx]
    return t(r[:, [c["x"], c["y"], c["z"]]]), torch.sort(t(r[:, [c["scale_0"], c["scale_1"], c["scale_2"]]]), 1).values

# A VGS record may change colour and opacity per frame, not scale: a partner is a NAIF splat of
# f+1 within half a size of the moved position with every sorted scale within 30 %.
for f in FRAMES[:-1]:
    (_, ia, ra), (_, ib, rb) = plan[f], plan[f + 1]
    if len(ia) == 0 or len(ib) == 0: continue
    pa, sa = attrs(ra, cnf, ia); pb, sb = attrs(rb, cnf, ib)
    k, dist = nn_search(advect(pa, f), pb)
    size = torch.exp(sa[:, 2])
    ok = (dist < 0.5 * size) & ((sa - sb[k]).abs().max(1).values < np.log(1.3))
    print(f"  {f}->{f + 1}: transplants with a partner (position + scale) {ok.float().mean() * 100:.1f} %, "
          f"position only {(dist < 0.5 * size).float().mean() * 100:.1f} %", flush=True)

# --- 3. sequences: per-frame transplants (TPO_A) and keyframe transplants carried 8 frames (TPO_K)
KEYS = [f for f in FRAMES if (f - FRAMES[0]) % 8 == 0]
carried = {}  # frame -> (key frame, NAIF indices of the key, positions at this frame)
for kf in KEYS:
    idx = plan[kf][1]
    p = t(plan[kf][2][idx][:, [cnf["x"], cnf["y"], cnf["z"]]])
    for g in range(kf, min(kf + 8, FRAMES[-1] + 1)):
        carried[g] = (kf, idx, p.cpu().numpy())
        if g + 1 <= FRAMES[-1]: p = advect(p, g)
print(f"keyframes {KEYS}", flush=True)

DEAD = -20.0
perm = [cnf[p] for p in cst]
def write_seq(name, keyed):
    out = f"{TC}/{name}"
    os.makedirs(f"{out}/frames", exist_ok=True); os.makedirs(f"{out}_vgs_in", exist_ok=True)
    if keyed:
        base = {kf: NST + sum(len(plan[k][1]) for k in KEYS if k < kf) for kf in KEYS}
        n = NST + sum(len(plan[k][1]) for k in KEYS)
    else:
        base = {f: NST + sum(len(plan[g][1]) for g in FRAMES if g < f) for f in FRAMES}
        n = NST + sum(len(plan[g][1]) for g in FRAMES)
    for k in range(32):
        f = FIRST + k
        rst = st7l(f) if f in FRAMES else load(f"{TC}/ST7L_clean/frames/{k:03d}/splat.ply")[1]
        rows = np.zeros((n, rst.shape[1]), np.float32); rows[:, cst["opacity"]] = DEAD
        rows[:, cst["rot_0"]] = 1.0; rows[:, [cst["scale_0"], cst["scale_1"], cst["scale_2"]]] = -10.0
        rows[:NST] = rst
        if f in plan:
            rows[np.nonzero(plan[f][0])[0], cst["opacity"]] = DEAD
            if keyed:
                kf, idx, p = carried[f]
                block = plan[kf][2][idx][:, perm]
                block[:, [cst["x"], cst["y"], cst["z"]]] = p
                rows[base[kf]:base[kf] + len(idx)] = block
            else:
                idx = plan[f][1]
                rows[base[f]:base[f] + len(idx)] = plan[f][2][idx][:, perm]
        os.makedirs(f"{out}/frames/{k:03d}", exist_ok=True)
        H.write_ply(f"{out}/frames/{k:03d}/splat.ply", head_st, rows)
        H.write_ply(f"{out}_vgs_in/{f:08d}.ply", head_st, rows)
    for d in (f"{out}/frames", f"{out}_vgs_in"):
        with open(f"{d}/birth_events.tsv", "w") as fh:
            fh.writelines(f"0\t{r}\t1\n" for r in range(n))
    print(f"{name}: {n} rows written", flush=True)

if not os.environ.get("TPO_FRAMES"):
    write_seq("TPO_K", True)
    write_seq("TPO_A", False)
