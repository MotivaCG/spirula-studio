"""Fit per frame and regional flicker per pair for .seq runs over a frame range."""
import sys
sys.path.insert(0, "."); import evaluate as e
a, b = map(int, sys.argv[1].split(":")); e.set_frames(a, b)
for run in sys.argv[2:]:
    plys = e.run_plys(run)
    fit = [e.fit_quality(p, f, f"{run}_{f}") for p, f in zip(plys, e.FRAMES)]
    det = [e.detail_quality(f"{run}_{f}") for f in e.FRAMES]
    rf = e.render_flicker(run)
    print(f"{run:10s} fit mean {sum(fit)/len(fit):.2f} detail mean {sum(det)/len(det):.2f} | fit " +
          " ".join(f"{f}:{q:.1f}" for f, q in zip(e.FRAMES, fit)) +
          f" | regional {rf[3]*1000:.1f}: " + " ".join(f"{e.FRAMES[t]}>{e.FRAMES[t]+1}:{v*1000:.1f}" for t, v in enumerate(rf[4])), flush=True)
