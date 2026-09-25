"""Gracia frames as 3DGS PLYs, and our cameras moved into Gracia's frame, for rendering."""
import json, os, shutil, struct, sys
import numpy as np
sys.path.insert(0, "."); import evaluate as e

C0 = 0.28209479177387814
T = json.load(open("gracia_to_colmap.json")); s, R, t = T["s"], np.array(T["R"]), np.array(T["t"])
OUT = f"{e.HERE}/gracia"
os.makedirs(f"{OUT}/data/sparse", exist_ok=True)

def quat_to_R(w, x, y, z):
    return np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)], [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                     [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])

def R_to_quat(M):
    w = np.sqrt(max(0, 1 + M[0, 0] + M[1, 1] + M[2, 2])) / 2
    if w > 1e-6:
        return np.array([w, (M[2, 1] - M[1, 2]) / (4 * w), (M[0, 2] - M[2, 0]) / (4 * w), (M[1, 0] - M[0, 1]) / (4 * w)])
    i = int(np.argmax(np.diag(M))); j, k = (i + 1) % 3, (i + 2) % 3
    r = np.sqrt(1 + M[i, i] - M[j, j] - M[k, k]); q = np.zeros(4)
    q[1 + i] = r / 2; q[1 + j] = (M[j, i] + M[i, j]) / (2 * r); q[1 + k] = (M[k, i] + M[i, k]) / (2 * r)
    q[0] = (M[k, j] - M[j, k]) / (2 * r); return q

# Cameras: X_cam = Rc (s R Xg + t) + tc, and dividing by s leaves the projection unchanged.
src = f"{e.frame_dir(45)}/sparse"
shutil.copy(f"{src}/cameras.bin", f"{OUT}/data/sparse/cameras.bin")
with open(f"{src}/images.bin", "rb") as f, open(f"{OUT}/data/sparse/images.bin", "wb") as g:
    n = struct.unpack("<Q", f.read(8))[0]; g.write(struct.pack("<Q", n))
    for _ in range(n):
        iid, qw, qx, qy, qz, tx, ty, tz, cid = struct.unpack("<idddddddi", f.read(64))
        name = b""
        while (c := f.read(1)) != b"\0": name += c
        npts = struct.unpack("<Q", f.read(8))[0]; pts = f.read(npts * 24)
        Rc = quat_to_R(qw, qx, qy, qz); tc = np.array([tx, ty, tz])
        Rn = Rc @ R; tn = (Rc @ t + tc) / s; q = R_to_quat(Rn)
        g.write(struct.pack("<idddddddi", iid, *q, *tn, cid) + name + b"\0" + struct.pack("<Q", npts) + pts)
with open(f"{src}/points3D.bin", "rb") as f, open(f"{OUT}/data/sparse/points3D.bin", "wb") as g:
    n = struct.unpack("<Q", f.read(8))[0]; g.write(struct.pack("<Q", n))
    for _ in range(n):
        pid, x, y, z, r_, g_, b_, err = struct.unpack("<QdddBBBd", f.read(43))
        tl = struct.unpack("<Q", f.read(8))[0]; track = f.read(tl * 8)
        p = R.T @ (np.array([x, y, z]) - t) / s
        g.write(struct.pack("<QdddBBBd", pid, *p, r_, g_, b_, err) + struct.pack("<Q", tl) + track)

def write_ply(path, dump):
    raw = open(dump, "rb").read(); n = int(np.frombuffer(raw[:8], np.uint64)[0]); o = 8; F = {}
    for name, k in [("pos", 3), ("scl", 3), ("opa", 1), ("col", 3), ("rot", 4)]:
        a = np.frombuffer(raw[o:o + 4 * n * k], np.float32); o += 4 * n * k
        F[name] = a.reshape(n, k) if k > 1 else a
    act = np.frombuffer(raw[o:o + n], np.uint8).astype(bool); o += n
    sh = np.frombuffer(raw[o:o + 4 * n * 45], np.float32).reshape(n, 15, 3)
    m = act
    opa = np.clip(F["opa"][m], 1e-6, 1 - 1e-6)
    cols = [F["pos"][m], np.zeros((m.sum(), 3), np.float32), (F["col"][m] - 0.5) / C0,
            sh[m].transpose(0, 2, 1).reshape(-1, 45), np.log(opa / (1 - opa))[:, None],
            np.log(np.maximum(F["scl"][m], 1e-12)), F["rot"][m][:, [3, 0, 1, 2]]]
    data = np.concatenate(cols, 1).astype(np.float32)
    names = ["x", "y", "z", "nx", "ny", "nz", "f_dc_0", "f_dc_1", "f_dc_2"] + [f"f_rest_{i}" for i in range(45)] + \
            ["opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"]
    head = "ply\nformat binary_little_endian 1.0\nelement vertex %d\n" % len(data) + \
           "".join(f"property float {p}\n" for p in names) + "end_header\n"
    with open(path, "wb") as f: f.write(head.encode("ascii")); f.write(data.tobytes())
    return len(data)

for fr in [int(a) for a in sys.argv[1:]] or e.FRAMES:
    print(fr, write_ply(f"{OUT}/gracia_{fr}.ply", e.gracia_dump(fr)), "splats")
