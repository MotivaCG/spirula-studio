"""B3 table: fit, detail, flicker, counts and coverage for Ws and the three new variants."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import evaluate as e, population as pop
e.set_frames(50, 60)
print("run  | fit | detail | flicker | live k >0.1 50->60 | coverage 50->60")
for run in ["Ws.seq", "B3b.seq", "B3c.seq", "B3d.seq"]:
    plys = pop.plys_of(run, 50)
    fit = [e.fit_quality(p, f, f"{run}_{f}") for p, f in plys]
    det = [e.detail_quality(f"{run}_{f}") for _, f in plys]
    rf = e.render_flicker(run)
    (a0, b0, c0), cov0 = pop.measure(*plys[0]); (a1, b1, c1), cov1 = pop.measure(*plys[-1])
    print(f"{run:8s}| {sum(fit)/len(fit):.2f} | {sum(det)/len(det):.2f} | {rf[3]*1000:.2f} | "
          f"{b0 // 1000}k->{b1 // 1000}k | {cov0 * 100:.0f}%->{cov1 * 100:.0f}%", flush=True)
