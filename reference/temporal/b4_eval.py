"""B4 table over 45-76: fit (mean, 45, 76), detail, regional flicker, coverage 45/60/76."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import evaluate as e, population as pop
e.set_frames(45, 76)
print("run | fit mean (45 / 76) | detail mean | flicker | coverage 45/60/76 | live >0.1 45/76")
def cov_cells(plys):
    out = {}
    for p, f in plys:
        if f in (45, 60, 76): out[f] = pop.measure(p, f)
    return out
for name, tags, plys in [
        ("gracia", [f"gracia_{f}" for f in e.FRAMES], None),
        ("forge", [f"forge_{f}" for f in e.FRAMES], pop.plys_of("forge", 45)),
        ("C3.seq", [f"C3.seq_{f}" for f in e.FRAMES], pop.plys_of("C3.seq", 45)),
        ("B4a.seq", [f"B4a.seq_{f}" for f in e.FRAMES], pop.plys_of("B4a.seq", 45)),
        ("B4b.seq", [f"B4b.seq_{f}" for f in e.FRAMES], pop.plys_of("B4b.seq", 45))]:
    ply_list = [p for p, _ in plys] if plys else [None] * len(e.FRAMES)
    fit = [e.fit_quality(p, f, t) for p, f, t in zip(ply_list, e.FRAMES, tags)]
    det = [e.detail_quality(t) for t in tags]
    rf = e.render_flicker(name if name != "C3.seq" else "C3.seq")
    line = f"{name:8s}| {sum(fit)/len(fit):.2f} ({fit[0]:.1f} / {fit[-1]:.1f}) | {sum(det)/len(det):.2f} | {rf[3]*1000:.2f}"
    if plys:
        c = cov_cells(plys)
        line += " | " + "/".join(f"{c[f][1]*100:.0f}%" for f in (45, 60, 76)) + f" | {c[45][0][1]//1000}k/{c[76][0][1]//1000}k"
    print(line, flush=True)
