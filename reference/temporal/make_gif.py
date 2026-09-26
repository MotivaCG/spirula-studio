"""Side-by-side loop of one fixed camera: video, Forge chain, a chunk run, Gracia."""
import sys
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, "."); import evaluate as e

def panel_frames(tag, cam):
    """Renders, videos and masks of one camera over FRAMES; a frame the eval loader
    skipped for that camera repeats the previous one."""
    qdirs = [f"{e.HERE}/q/{tag}_{f}" for f in e.FRAMES]
    views = [e.camera_views(q) for q in qdirs]
    load = lambda p: np.asarray(Image.open(p), np.float32) / 255
    R, G, M = [], [], []
    for q, v in zip(qdirs, views):
        if cam not in v:
            R.append(R[-1] if R else None); G.append(G[-1] if G else None); M.append(M[-1] if M else None)
            continue
        R.append(load(f"{q}/eval-render-{v[cam][0]:05d}.png")); G.append(load(f"{q}/eval-gt-{v[cam][0]:05d}.png"))
        M.append(np.asarray(Image.open(v[cam][1]).convert("L").resize(G[-1].shape[1::-1])) > 127)
    first = next(i for i, g in enumerate(G) if g is not None)
    for i in range(first):
        R[i], G[i], M[i] = R[first], G[first], M[first]
    r = np.concatenate([x[m] for x, m in zip(R, M)]); g = np.concatenate([x[m] for x, m in zip(G, M)])
    coef = [np.linalg.lstsq(np.stack([r[:, c], np.ones(len(r))], 1), g[:, c], rcond=None)[0] for c in range(3)]
    R = [np.clip(np.stack([x[..., c] * coef[c][0] + coef[c][1] for c in range(3)], -1), 0, 1) for x in R]
    return R, G, M

run = sys.argv[1]; out = sys.argv[2]
if len(sys.argv) > 4:  # optional first:last
    a, b = sys.argv[4].split(":"); e.set_frames(int(a), int(b))
from collections import Counter
present = Counter(c for tag in ("forge", run, "gracia") for f in e.FRAMES
                  for c in e.camera_views(f"{e.HERE}/q/{tag}_{f}"))
common = [c for c, _ in present.most_common()]
cam = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] in common else common[0]
print("camera", cam, "of", common)
Rf, G, M = panel_frames("forge", cam)
Rc, _, _ = panel_frames(run, cam)
Rg, _, _ = panel_frames("gracia", cam)
ys, xs = np.nonzero(np.any(M, 0))
y0, y1 = max(ys.min() - 20, 0), min(ys.max() + 20, G[0].shape[0]); x0, x1 = max(xs.min() - 20, 0), min(xs.max() + 20, G[0].shape[1])
frames = []
for t in range(len(G)):
    tiles = [x[y0:y1, x0:x1] for x in (G[t], Rf[t], Rc[t], Rg[t])]
    img = Image.fromarray((np.concatenate(tiles, 1) * 255).astype(np.uint8))
    sc = 900 / img.height; img = img.resize((int(img.width * sc), 900))
    d = ImageDraw.Draw(img); w = img.width // 4
    for i, name in enumerate(["video", "Forge chain", f"chunk {run}", "Gracia"]):
        d.rectangle([i * w, 0, i * w + 160, 26], fill=(0, 0, 0)); d.text((i * w + 6, 6), f"{name}  f{e.FRAMES[t]}", fill=(255, 255, 255))
    frames.append(img)
frames += frames[-2:0:-1]  # ping-pong so the loop has no jump
frames[0].save(out, save_all=True, append_images=frames[1:], duration=170, loop=0)
print(out, len(frames), "frames")
