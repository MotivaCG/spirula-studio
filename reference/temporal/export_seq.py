"""Copy a run's frames into one folder named by take frame, for playing them as a sequence.

python export_seq.py <run | name.seq> <first_frame> <out_dir>
Writes <out_dir>/NNNN.ply (take frame number, 4 digits), one per frame, unpruned.
"""
import os, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import population as pop

run, first, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
os.makedirs(out, exist_ok=True)
for ply, frame in pop.plys_of(run, first):
    shutil.copyfile(ply, os.path.join(out, f"{frame:04d}.ply"))
print(out, len(os.listdir(out)), "files")
