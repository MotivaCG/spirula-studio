"""Visual-hull subject selection: splats whose centre lies inside the mask in most views."""
import functools, os, struct
import numpy as np
from PIL import Image

def _images_bin(p):
    out = []
    with open(p, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            iid, qw, qx, qy, qz, tx, ty, tz, cid = struct.unpack("<idddddddi", f.read(64))
            name = b""
            while (c := f.read(1)) != b"\0": name += c
            npts = struct.unpack("<Q", f.read(8))[0]; f.seek(npts * 24, 1)
            w, x, y, z = qw, qx, qy, qz
            R = np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                          [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                          [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])
            out.append((name.decode(), R, np.array([tx, ty, tz]), cid))
    return out

def _cameras_bin(p):
    out = {}
    with open(p, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            cid, model, w, h = struct.unpack("<iiQQ", f.read(24))
            npar = {0: 3, 1: 4, 2: 4, 3: 5, 4: 8, 5: 8}[model]
            prm = struct.unpack(f"<{npar}d", f.read(8 * npar))
            fx, fy, cx, cy = (prm[0], prm[0], prm[1], prm[2]) if model in (0, 2, 3) else prm[:4]
            out[cid] = (w, h, fx, fy, cx, cy)
    return out

@functools.lru_cache(maxsize=16)
def _views(frame_dir, scale=4):
    ims = _images_bin(f"{frame_dir}/sparse/images.bin"); cams = _cameras_bin(f"{frame_dir}/sparse/cameras.bin")
    views = []
    for name, R, t, cid in ims:
        w, h, fx, fy, cx, cy = cams[cid]
        m = Image.open(f"{frame_dir}/masks/{os.path.splitext(name)[0]}.png").convert("L")
        m = np.asarray(m.resize((w // scale, h // scale))) > 127
        views.append((R, t, fx / scale, fy / scale, cx / scale, cy / scale, m))
    return views

def subject(pos, frame_dir, ratio=0.9, min_views=10):
    """Boolean keep-mask over pos [N, 3], COLMAP world frame."""
    inside = np.zeros(len(pos), np.int32); seen = np.zeros(len(pos), np.int32)
    for R, t, fx, fy, cx, cy, m in _views(frame_dir):
        pc = pos @ R.T + t
        z = pc[:, 2]; ok = z > 1e-3
        u = np.full(len(pos), -1); v = np.full(len(pos), -1)
        u[ok] = np.floor(fx * pc[ok, 0] / z[ok] + cx).astype(int)
        v[ok] = np.floor(fy * pc[ok, 1] / z[ok] + cy).astype(int)
        ok &= (u >= 0) & (u < m.shape[1]) & (v >= 0) & (v < m.shape[0])
        seen += ok
        inside[ok] += m[v[ok], u[ok]]
    return (seen >= min_views) & (inside >= ratio * np.maximum(seen, 1))
