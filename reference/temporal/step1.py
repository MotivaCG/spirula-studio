"""Step 1 of the revised plan: full metrics on 50-60 for references and the window runs."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import evaluate as e, population as pop
e.set_frames(50, 60)
def row(name, fit_tags, flick_tag, plys):
    fit = [e.fit_quality(p, f, t) for p, f, t in zip(plys, e.FRAMES, fit_tags)]
    det = [e.detail_quality(t) for t in fit_tags]
    rf = e.render_flicker(flick_tag)
    line = (f"{name:8s} fit {sum(fit)/len(fit):.2f} (50:{fit[0]:.1f} 60:{fit[-1]:.1f}) | detail {sum(det)/len(det):.2f} "
            f"(50:{det[0]:.1f} 60:{det[-1]:.1f}) | flicker {rf[3]*1000:.2f} px {rf[0]*1000:.2f}")
    print(line, flush=True)
# Gracia: only render metrics (its splats live in another frame).
row("gracia", [f"gracia_{f}" for f in e.FRAMES], "gracia", [None] * len(e.FRAMES))
fp = pop.plys_of("forge", 50)
row("forge", [f"forge_{f}" for f in e.FRAMES], "forge", [p for p, _ in fp])
for run in ["R1.seq", "Wd.seq", "Wg.seq", "Wj.seq", "Ws.seq"]:
    plys = [p for p, _ in pop.plys_of(run, 50)]
    row(run, [f"{run}_{f}" for f in e.FRAMES], run, plys)
print("--- population (live k at >0.02 / >0.1 / >0.5, coverage)", flush=True)
for run in ["forge", "R1.seq", "Wd.seq", "Wg.seq", "Wj.seq", "Ws.seq"]:
    cells = []
    for ply, f in pop.plys_of(run, 50):
        if f not in (50, 55, 60): continue
        (a, b, c), cov = pop.measure(ply, f)
        cells.append(f"{f}: {a // 1000}/{b // 1000}/{c // 1000}k cov {cov * 100:.0f}%")
    print(f"{run:8s} " + " | ".join(cells), flush=True)
