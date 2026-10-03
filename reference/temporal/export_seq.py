"""Copy a run's frames into one folder named by take frame, for playing them as a sequence.

python export_seq.py <run | name.seq> <first_frame> <out_dir>
Writes <out_dir>/NNNN.ply (take frame number, 4 digits), one per frame, unpruned.
"""
import os, shutil, sys
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import population as pop

run, first, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
os.makedirs(out, exist_ok=True)
plys = pop.plys_of(run, first)
sources = {Path(ply).parent.parent / 'birth_events.tsv' for ply, _ in plys}
with_events = [path for path in sources if path.exists()]
if len(with_events) > 1:
    raise ValueError('Cannot merge birth events from separate temporal runs')
for ply, frame in plys:
    shutil.copyfile(ply, os.path.join(out, f"{frame:04d}.ply"))
if with_events:
    shutil.copyfile(with_events[0], os.path.join(out, 'birth_events.tsv'))
print(out, len(os.listdir(out)), "files")
