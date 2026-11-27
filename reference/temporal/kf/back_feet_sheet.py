"""Back and feet crops at full resolution: video | Gracia | NAIF | <runs>, from the camera of the
face camera's ring that looks at the man from behind. Gracia is rendered in its own frame with our
cameras moved there (gracia_to_colmap.json), so its SH stay exact.
Usage (ref4d venv, -I): back_feet_sheet.py <sheet.png> <run>... (frames from BFS_FRAMES, default 52 66 73)"""
import json, os, sys
sys.path[:0] = [os.path.dirname(os.path.abspath(__file__))]
src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "transplant_oracle.py"), encoding="utf8").read()
exec(src[src.index("import os, sys"):src.index("# --- 1.")])
from PIL import ImageDraw

sheet, runs = sys.argv[1], sys.argv[2:]
frames = [int(a) for a in os.environ.get("BFS_FRAMES", "52 66 73").split()]
FACE = ("SMN_V1_H5_P8", 610, 490)  # transplant_eval's face crop centre (row, col)
G = json.load(open(f"{TC}/gracia_to_colmap.json")); gs, gR, gt = G["s"], np.array(G["R"]), np.array(G["t"])


def model(run, f):
    if run == "Gracia": path = f"{TC}/gracia/gracia_{f}.ply"
    elif run == "NAIF": path = NAIF.format(f)
    else: path = f"{TC}/{run}/frames/{f - FIRST:03d}/splat.ply"
    _, rows, c = load(path)
    return splats(rows, c)


def view(run, s, R, T, K, W, Hh):
    if run == "Gracia": R, T = R @ gR, (R @ gt + T) / gs
    return (render(s, R, T, K, W, Hh)[0].cpu().numpy() * 255).astype(np.uint8)


def box(R, T, K, pts, W, Hh, pad=40):
    x = pts @ R.T + T
    u, v = K[0, 0] * x[:, 0] / x[:, 2] + K[0, 2], K[1, 1] * x[:, 1] / x[:, 2] + K[1, 2]
    return (max(int(v.min()) - pad, 0), min(int(v.max()) + pad, Hh), max(int(u.min()) - pad, 0), min(int(u.max()) + pad, W))


rows_out = []
for f in frames:
    ms = {r: model(r, f) for r in ["Gracia", "NAIF"] + runs}
    ref = ms["NAIF"]
    # The man's head from the face camera's depth, then the most opposite camera of that ring.
    R, T, K, W, Hh = cam(f, FACE[0], 1)
    _, d, _ = render(ref, R, T, K, W, Hh)
    z = float(d[FACE[1], FACE[2]])
    head = R.T @ (np.array([(FACE[2] + 0.5 - K[0, 2]) / K[0, 0] * z, (FACE[1] + 0.5 - K[1, 2]) / K[1, 1] * z, z]) - T)
    centre = lambda n: -cam(f, n, 1)[0].T @ cam(f, n, 1)[1]
    dirxz = lambda n: (lambda v: v / np.linalg.norm(v))((centre(n) - head)[[0, 2]])
    ring = FACE[0].split("_P")[0]
    back = min((n for n in H.names(f) if n.startswith(ring + "_P")), key=lambda n: float(dirxz(n) @ dirxz(FACE[0])))
    R, T, K, W, Hh = cam(f, back, 1)
    pos = ref["pos"].cpu().numpy(); op = ref["op"].cpu().numpy()
    near_man = (np.linalg.norm((pos - head)[:, [0, 2]], axis=1) < 0.35) & (op > 0.5)
    torso = pos[near_man & (pos[:, 1] > 0.9) & (pos[:, 1] < 1.6)]
    feet = pos[(op > 0.5) & (pos[:, 1] < 0.15) & (np.linalg.norm((pos - head)[:, [0, 2]], axis=1) < 0.9)]
    vid = np.asarray(Image.open(f"{H.frame_dir(f)}/images/{back}.png").convert("RGB"))
    imgs = [vid] + [view(r, ms[r], R, T, K, W, Hh) for r in ["Gracia", "NAIF"] + runs]
    for part, pts in (("back", torso), ("feet", feet)):
        y0, y1, x0, x1 = box(R, T, K, pts, W, Hh)
        rows_out.append((f"frame {f} {back} {part}: video | Gracia | NAIF | " + " | ".join(runs), [a[y0:y1, x0:x1] for a in imgs]))
    print(f, back, "head", np.round(head, 3), flush=True)

w = max(sum(x.shape[1] + 8 for x in r) for _, r in rows_out)
img = Image.new("RGB", (w, sum(r[0].shape[0] + 22 for _, r in rows_out)), "white"); dr = ImageDraw.Draw(img); y = 0
for label, r in rows_out:
    dr.text((4, y + 4), label, fill="black"); x = 0
    for a in r: img.paste(Image.fromarray(np.ascontiguousarray(a)), (x, y + 22)); x += a.shape[1] + 8
    y += r[0].shape[0] + 22
img.save(sheet)
print(sheet)
