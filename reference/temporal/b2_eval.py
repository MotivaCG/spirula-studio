"""B2 table: subject population (3 thresholds + coverage) for the repeated-frame controls."""
import glob, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import population as pop
H = pop.e.HERE
def cell(ply, f):
    (a, b, c), cov = pop.measure(ply, f)
    return f"{a // 1000}/{b // 1000}/{c // 1000}k cov{cov * 100:.0f}%"
print("run  | frame 50 (first) | frame 55 | frame 60 (last)   [live k >0.02/>0.1/>0.5, coverage]")
for run in ["RF1.seq", "RF3.seq", "Wd.seq", "R1.seq"]:
    plys = pop.plys_of(run, 50)
    motionless = run.startswith("RF")
    cells = [cell(p, 50 if motionless else f) for p, f in plys if f in (50, 55, 60)]
    print(f"{run:7s}| " + " | ".join(cells))
rf2 = sorted(glob.glob(f"{H}/RF2/step-*.ckpt"))[-1] + "/splat.ply"
init = sorted(glob.glob(f"{pop.e.frame_dir(50)}/smn/step-*.ckpt/splat.ply"))[-1]
print(f"RF2    | continuous 64k steps on frame 50: {cell(rf2, 50)}   (start {cell(init, 50)})")
