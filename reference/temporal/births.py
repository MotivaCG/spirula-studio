"""Birth candidates per frame: the subject's SfM points with colour and local spacing.

python births.py <first> <last> <outdir>
Writes <outdir>/NNN.bin for take index NNN = f - first: int32 count, then float32 rows
[x, y, z, r, g, b (0..1), spacing (distance to the 4th nearest subject point)].
"""
import os, struct, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hull, warps

def points(frame):
    xyz, rgb = [], []
    with open(f"{warps.WORK}/000000{frame}/undistorted/sparse/points3D.bin", "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            _, x, y, z, r, g, b, _ = struct.unpack("<QdddBBBd", f.read(43))
            tl = struct.unpack("<Q", f.read(8))[0]; f.seek(tl * 8, 1)
            xyz.append((x, y, z)); rgb.append((r, g, b))
    xyz, rgb = np.array(xyz), np.array(rgb, np.float64) / 255
    keep = hull.subject(xyz, f"{warps.WORK}/000000{frame}/undistorted", ratio=0.8, min_views=6)
    return xyz[keep], rgb[keep]

if __name__ == "__main__":
    first, last, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    os.makedirs(out, exist_ok=True)
    for f in range(first + 1, last + 1):
        xyz, rgb = points(f)
        d, _ = warps.Grid(xyz, 0.02).knn(xyz, 5, 2)
        spacing = np.where(np.isfinite(d[:, 4]), d[:, 4], 0.02)
        rows = np.concatenate([xyz, rgb, spacing[:, None]], 1).astype(np.float32)
        with open(f"{out}/{f - first:03d}.bin", "wb") as fh:
            fh.write(struct.pack("<i", len(rows))); fh.write(rows.tobytes())
        print(f"{f}: {len(rows)} subject points, median spacing {np.median(spacing) * 1000:.1f} mm", flush=True)
