"""B5 table over 45-64: fit, detail, flicker (mean and per pair), coverage at 64."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import evaluate as e, population as pop
e.set_frames(45, 64)
for run in ["C3.seq", "B4a.seq", "B5a.seq", "B5c.seq"]:
    plys = pop.plys_of(run, 45)[:len(e.FRAMES)]
    fit = [e.fit_quality(p, f, f"{run}_{f}") for p, f in plys]
    det = [e.detail_quality(f"{run}_{f}") for _, f in plys]
    rf = e.render_flicker(run)
    (_, b, _), cov = pop.measure(*plys[-1])
    print(f"{run:8s} fit {sum(fit)/len(fit):.2f} detail {sum(det)/len(det):.2f} flicker {rf[3]*1000:.2f} "
          f"cov64 {cov*100:.0f}% live64 {b//1000}k | " + " ".join(f"{e.FRAMES[i]}:{v*1000:.0f}" for i, v in enumerate(rf[4])), flush=True)
