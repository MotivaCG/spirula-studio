"""Live subject splats (opacity > 0.1 inside the visual hull) per frame of chunk runs."""
import glob, os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import evaluate as e

def subject_alive(ply, frame):
    F = e.fl.ply_frame(ply); m = e.hull.subject(F["pos"], e.frame_dir(frame))
    return int(((F["opa"] > 0.1) & m).sum())

first = int(sys.argv[1])
for run in sys.argv[2:]:
    if run.endswith(".seq"):
        rows = [l.split() for l in open(f"{e.HERE}/{run}")]
        plys = [(sorted(glob.glob(f"{e.HERE}/{r}/step-*.ckpt"))[-1] + "/splat.ply", int(f)) for f, r, _ in rows]
        counts = [subject_alive(p, f) for p, f in plys]
        print(f"{run:8s} " + " ".join(f"{f}:{c}" for (_, f), c in zip(plys, counts)), flush=True)
        continue
    dirs = sorted(glob.glob(f"{e.HERE}/{run}/frames/[0-9][0-9][0-9]"))
    if dirs:
        plys = [(f"{d}/splat.ply", first + i) for i, d in enumerate(dirs)]
    else:  # a single-frame run writes step-*.ckpt
        plys = [(sorted(glob.glob(f"{e.HERE}/{run}/step-*.ckpt"))[-1] + "/splat.ply", first)]
    counts = [subject_alive(p, f) for p, f in plys]
    print(f"{run:6s} " + " ".join(f"{f}:{c}" for (_, f), c in zip(plys, counts)), flush=True)
