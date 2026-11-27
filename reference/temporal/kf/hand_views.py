"""Off-rig look at one spot: virtual cameras around a training camera (yaw / pitch about the spot,
dolly in), each run rendered with its SH; one row per view, one column per run, GT camera first.
The spot = mean of the first run's records drawing the pixel box (as hand_diag.py).
Usage (ref4d venv, -I): hand_views.py <first> <k> <camera index> <x0> <y0> <x1> <y1> <out.png> <run>..."""
import os, sys
sys.path[:0] = [os.path.dirname(os.path.abspath(__file__))]
import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image, ImageDraw
from gsplat.rendering import rasterization
import ho_lib as H

first, k, ci = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
x0, y0, x1, y1 = map(int, sys.argv[4:8])
out, runs = sys.argv[8], sys.argv[9:]
TC = "D:/Dependencias/spirula-studio/outputs/tc"
dev = "cuda"
f = first + k
name = H.names(f)[ci]
cams, imgs = H.read_cameras(f"{H.frame_dir(f)}/sparse/cameras.bin"), H.read_images(f"{H.frame_dir(f)}/sparse/images.bin")
qv, tv, cid, _ = imgs[name]
_, W, Hh, prm = cams[cid]
R0, T0 = H.qrot(qv), np.asarray(tv)
K = np.array([[prm[0], 0, prm[2]], [0, prm[1], prm[3]], [0, 0, 1]])
t = lambda a: torch.tensor(np.asarray(a), dtype=torch.float32, device=dev)


def load(path):
    _, rows, props = H.read_ply(path)
    c = {p: i for i, p in enumerate(props)}
    g = lambda *ks: rows[:, [c[x] for x in ks]].astype(np.float64)
    rest = sorted((p for p in props if p.startswith("f_rest_")), key=lambda p: int(p[7:]))
    nb = len(rest) // 3
    sh = np.concatenate([g("f_dc_0", "f_dc_1", "f_dc_2")[:, None],
                         g(*rest).reshape(-1, 3, nb).transpose(0, 2, 1)], 1) if nb else g("f_dc_0", "f_dc_1", "f_dc_2")[:, None]
    return dict(pos=g("x", "y", "z"), sh=sh, op=1 / (1 + np.exp(-g("opacity")[:, 0])),
                sc=np.exp(g("scale_0", "scale_1", "scale_2")), q=g("rot_0", "rot_1", "rot_2", "rot_3"))


def render(s, R, T):
    vm = torch.eye(4, device=dev); vm[:3, :3] = t(R); vm[:3, 3] = t(T)
    deg = int(round(np.sqrt(s["sh"].shape[1]))) - 1
    img, _, _ = rasterization(t(s["pos"]), F.normalize(t(s["q"]), dim=1), t(s["sc"]), t(s["op"]), t(s["sh"]),
                              vm[None], t(K)[None], W, Hh, sh_degree=deg)
    return np.clip(img[0].cpu().numpy(), 0, 1)


def rot(axis, deg):
    a = np.radians(deg); x, y, z = axis / np.linalg.norm(axis); c, s_ = np.cos(a), np.sin(a)
    return np.array([[c + x * x * (1 - c), x * y * (1 - c) - z * s_, x * z * (1 - c) + y * s_],
                     [y * x * (1 - c) + z * s_, c + y * y * (1 - c), y * z * (1 - c) - x * s_],
                     [z * x * (1 - c) - y * s_, z * y * (1 - c) + x * s_, c + z * z * (1 - c)]])


models = {r: load(f"{TC}/{r}/frames/{k:03d}/splat.ply") for r in runs}
s = models[runs[0]]
xc = s["pos"] @ R0.T + T0
u, v = K[0, 0] * xc[:, 0] / xc[:, 2] + K[0, 2], K[1, 1] * xc[:, 1] / xc[:, 2] + K[1, 2]
sel = (xc[:, 2] > 0.05) & (u >= x0) & (u < x1) & (v >= y0) & (v < y1) & (s["op"] > 0.3)
spot = np.median(s["pos"][sel], 0)
cam_c = -R0.T @ T0
up = -R0[1]  # camera y points down
right = R0[0]
views = [("rig", np.eye(3), 1.0), ("yaw -30", rot(up, -30), 1.0), ("yaw +30", rot(up, 30), 1.0),
         ("pitch +25", rot(right, 25), 1.0), ("pitch -25", rot(right, -25), 1.0), ("dolly x0.5", np.eye(3), 0.5)]
half = (x1 - x0) // 2 + 60
rows = []
for label, Rv, dist in views:
    c = spot + Rv @ (cam_c - spot) * dist
    Rw = R0 @ Rv.T  # world -> camera, the camera turned with its position
    T = -Rw @ c
    p = Rw @ spot + T
    cu, cv = int(K[0, 0] * p[0] / p[2] + K[0, 2]), int(K[1, 1] * p[1] / p[2] + K[1, 2])
    hh = int(half / dist)
    box = (max(cu - hh, 0), max(cv - hh, 0), min(cu + hh, W), min(cv + hh, Hh))
    tiles = []
    if label == "rig":
        gt = np.asarray(Image.open(f"{H.frame_dir(f)}/images/{name}.png").convert("RGB"))
        tiles.append(gt[box[1]:box[3], box[0]:box[2]])
    else:
        tiles.append(np.zeros((box[3] - box[1], box[2] - box[0], 3), np.uint8))
    for r in runs:
        tiles.append((render(models[r], Rw, T)[box[1]:box[3], box[0]:box[2]] * 255).astype(np.uint8))
    row = Image.fromarray(np.concatenate(tiles, 1)).resize((260 * len(tiles), 260))
    ImageDraw.Draw(row).text((4, 4), label, fill=(255, 255, 0))
    rows.append(np.asarray(row))
head = Image.new("RGB", (rows[0].shape[1], 18))
for i, r in enumerate(["GT"] + runs): ImageDraw.Draw(head).text((i * 260 + 4, 3), r, fill=(255, 255, 255))
Image.fromarray(np.concatenate([np.asarray(head)] + rows, 0)).save(out)
print(f"frame {f}, camera {ci} {name}, spot {spot.round(3)} from {sel.sum()} records -> {out}")
