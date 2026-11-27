"""Keyframe seed for spirula's spacetime trainer (--spacetime-init <dst>), frames 45-76:
  <dst>/seed.ply     every record's splat at its keyframe, 3DGS layout, SH degree 1:
                     NAIF splat centres every 3rd frame (cropped, alpha > 0.1), DC colour,
                     alpha 0.1, identity rotation, isotropic scale 0.3 x mean 4-NN distance
                     in its keyframe's cloud (shape is learnt, not transported)
  <dst>/motion.bin   float32 [N, 8]: mu (keyframe, frames), sigma (3 frames), velocity and
                     acceleration per video frame from the 4 nearest ST7L records
Per keyframe `per_kf` points are drawn, then the budget is shared by keyframe in proportion,
the fastest quarter of each keyframe's share kept first, the rest at random.
Usage: st_keyframe_seed.py <dst> [budget] [per_kf]"""
import os
import sys

import numpy as np
from scipy.spatial import cKDTree

TC = 'D:/Dependencias/spirula-studio/outputs/tc'
FIRST, LAST, STEP = 45, 76, 3
SIGMA = 3.0
C0 = 0.28209479177387814
dst = sys.argv[1]
budget = int(sys.argv[2]) if len(sys.argv) > 2 else 760000
per_kf = int(sys.argv[3]) if len(sys.argv) > 3 else 150000


def read_ply(path):
    data = open(path, 'rb').read()
    end = data.index(b'end_header\n') + len(b'end_header\n')
    head = data[:end].decode('ascii')
    props = [l.split()[-1] for l in head.splitlines() if l.startswith('property float')]
    n = int([l for l in head.splitlines() if l.startswith('element vertex')][0].split()[-1])
    v = np.frombuffer(data, dtype='<f4', count=n * len(props), offset=end).reshape(n, len(props))
    return {p: v[:, i] for i, p in enumerate(props)}


st = [read_ply(f'{TC}/ST7L_clean/frames/{k:03d}/splat.ply') for k in range(LAST - FIRST + 1)]
st_xyz = [np.stack([s['x'], s['y'], s['z']], 1) for s in st]
st_a = [1.0 / (1.0 + np.exp(-s['opacity'])) for s in st]

rng = np.random.default_rng(12345)
kfs = list(range(0, LAST - FIRST + 1, STEP))
cohorts = []
for k in kfs:
    n = read_ply(f'{TC}/TRIGS_in/{FIRST + k:08d}.ply')
    alpha = 1.0 / (1.0 + np.exp(-n['opacity']))
    keep = np.flatnonzero(alpha > 0.1)
    if len(keep) > per_kf:
        keep = np.sort(rng.choice(keep, per_kf, replace=False))
    xyz = np.stack([n['x'], n['y'], n['z']], 1)[keep]
    dc = np.stack([n['f_dc_0'], n['f_dc_1'], n['f_dc_2']], 1)[keep]
    dist, _ = cKDTree(xyz).query(xyz, k=5, workers=-1)
    scale = np.log(np.maximum(0.3 * dist[:, 1:].mean(1), 1e-7))
    km, kp = max(k - 1, 0), min(k + 1, LAST - FIRST)
    live = np.flatnonzero((st_a[k] > 0.1) & (st_a[km] > 0.1) & (st_a[kp] > 0.1))
    _, nb = cKDTree(st_xyz[k][live]).query(xyz, k=4, workers=-1)
    rows = live[nb]
    vel = ((st_xyz[kp][rows] - st_xyz[km][rows]) / max(kp - km, 1)).mean(1)
    acc = (st_xyz[kp][rows] - 2 * st_xyz[k][rows] + st_xyz[km][rows]).mean(1) if kp - km == 2 else np.zeros_like(vel)
    cohorts.append((k, xyz, dc, scale, vel, acc))

total = sum(len(c[1]) for c in cohorts)
out = []
for k, xyz, dc, scale, vel, acc in cohorts:
    share = min(len(xyz), int(round(budget * len(xyz) / total)))
    speed = np.linalg.norm(vel, axis=1)
    fast = np.argsort(-speed)[:share // 4]
    rest = np.setdiff1d(np.arange(len(xyz)), fast)
    pick = np.sort(np.concatenate([fast, rng.choice(rest, share - len(fast), replace=False)]))
    out.append((k, xyz[pick], dc[pick], scale[pick], vel[pick], acc[pick]))
    print('keyframe', FIRST + k, len(pick), 'records, median speed mm/frame', round(float(np.median(speed[pick])) * 1000, 2))

n = sum(len(c[1]) for c in out)
cols = ['x', 'y', 'z', 'nx', 'ny', 'nz', 'f_dc_0', 'f_dc_1', 'f_dc_2'] + [f'f_rest_{i}' for i in range(9)] + \
       ['opacity', 'scale_0', 'scale_1', 'scale_2', 'rot_0', 'rot_1', 'rot_2', 'rot_3']
v = np.zeros((n, len(cols)), np.float32)
m = np.zeros((n, 8), np.float32)
i = 0
for k, xyz, dc, scale, vel, acc in out:
    j = i + len(xyz)
    v[i:j, 0:3] = xyz
    v[i:j, 6:9] = dc
    v[i:j, 18] = np.log(0.1 / 0.9)
    v[i:j, 19:22] = scale[:, None]
    v[i:j, 22] = 1.0
    m[i:j, 0] = k
    m[i:j, 1] = SIGMA
    m[i:j, 2:5] = vel
    m[i:j, 5:8] = acc
    i = j
os.makedirs(dst, exist_ok=True)
header = ['ply', 'format binary_little_endian 1.0', f'element vertex {n}'] + [f'property float {c}' for c in cols] + ['end_header']
with open(os.path.join(dst, 'seed.ply'), 'wb') as f:
    f.write(('\n'.join(header) + '\n').encode('ascii'))
    f.write(v.tobytes())
with open(os.path.join(dst, 'motion.bin'), 'wb') as f:
    f.write(m.tobytes())
print('seed', n, 'records')
