"""Phase 0 evaluation: ST7L, NAIF, TPO_A (per-frame transplant) and TPO_K (keyframe carried).
Per frame over every camera at half resolution: high-pass error vs the video (colour matched)
on the pixels where ST7L misses detail and on the whole mask, then full-resolution face crops.
Usage (ref4d venv, -I): transplant_eval.py <sheet.png> <frame>..."""
import os, sys
sys.path[:0] = [os.path.dirname(os.path.abspath(__file__))]
src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "transplant_oracle.py"), encoding="utf8").read()
exec(src[src.index("import os, sys"):src.index("# --- 1.")])
from PIL import ImageDraw

sheet, frames = sys.argv[1], [int(a) for a in sys.argv[2:]]
RUNS = os.environ.get("TPE_RUNS", "ST7L_clean NAIF TPO_A TPO_K").split()
FACE = ("SMN_V1_H5_P8", 420, 800, 300, 680)


def model(run, f):
    path = NAIF.format(f) if run == "NAIF" else f"{TC}/{run}/frames/{f - FIRST:03d}/splat.ply"
    _, rows, c = load(path)
    return splats(rows, c)


def hp_err(r, v, m):
    x, y, rr = r[m], v[m], r.clone()
    for ch in range(3):
        A = torch.stack([x[:, ch], torch.ones_like(x[:, ch])], 1)
        sol = torch.linalg.lstsq(A, y[:, ch:ch + 1]).solution[:, 0]
        rr[..., ch] = r[..., ch] * sol[0] + sol[1]
    hp = lambda img: blur(img @ LUM, 1.0) - blur(img @ LUM, 4.0)
    return (hp(rr) - hp(v)).abs()


crops = []
print("frame | HP error on ST7L's missing-detail pixels (x1000): " + " / ".join(RUNS) + " | on the whole mask: " + " / ".join(RUNS)
      + " | light, masked render/video luminance: " + " / ".join(RUNS), flush=True)
for f in frames:
    ms = {r: model(r, f) for r in RUNS}
    bad = {r: [] for r in RUNS}; whole = {r: [] for r in RUNS}; light = {r: [] for r in RUNS}
    for name in H.names(f):
        R, T, K, W, Hh = cam(f, name, DOWN)
        v = t(np.asarray(Image.open(f"{H.frame_dir(f)}/images/{name}.png").convert("RGB").resize((W, Hh), Image.BILINEAR), np.float32) / 255)
        m = torch.from_numpy(H.mask(f, name, down=DOWN, dilate=-0.01)).to(dev)
        r0, _, a0 = render(ms["ST7L_clean"], R, T, K, W, Hh)
        E = error_map(r0, v, m, a0)
        for run in RUNS:
            r = r0 if run == "ST7L_clean" else render(ms[run], R, T, K, W, Hh)[0]
            e = hp_err(r, v, m)
            if E.any(): bad[run].append(float(e[E].mean()))
            whole[run].append(float(e[m].mean()))
            light[run].append(float((r[m] @ LUM).mean() / (v[m] @ LUM).mean()))
        if name == FACE[0]:
            R1, T1, K1, W1, H1 = cam(f, name, 1)
            _, y0, y1, x0, x1 = FACE
            vid = np.asarray(Image.open(f"{H.frame_dir(f)}/images/{name}.png").convert("RGB"))[y0:y1, x0:x1]
            row = [vid] + [(render(ms[run], R1, T1, K1, W1, H1)[0][y0:y1, x0:x1].cpu().numpy() * 255).astype(np.uint8) for run in RUNS]
            crops.append((f, row))
    print(f"{f} | " + " / ".join(f"{np.mean(bad[r]) * 1000:.2f}" for r in RUNS) + " | " + " / ".join(f"{np.mean(whole[r]) * 1000:.2f}" for r in RUNS)
          + " | " + " / ".join(f"{np.mean(light[r]):.4f}" for r in RUNS), flush=True)

w, h = crops[0][1][0].shape[1], crops[0][1][0].shape[0]
img = Image.new("RGB", ((len(RUNS) + 1) * (w + 8), len(crops) * (h + 22)), "white"); dr = ImageDraw.Draw(img)
for i, (f, row) in enumerate(crops):
    dr.text((4, i * (h + 22) + 4), f"frame {f} {FACE[0]}: video | " + " | ".join(RUNS), fill="black")
    for j, x in enumerate(row): img.paste(Image.fromarray(x), (j * (w + 8), i * (h + 22) + 22))
img.save(sheet)
print(sheet)
