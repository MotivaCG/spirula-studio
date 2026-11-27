"""Shared pieces of the held-out evaluation (battery HO): the fg10 take's prepared frames, the
held-out cameras (spirula --eval-mode interval --eval-interval 8: every 8th name, sorted), COLMAP
readers, PLY rows and masks."""
import os, struct
import numpy as np
from PIL import Image, ImageFilter

WORK = "D:/Gracia4DGSConverter/VIDEOTIKI_CHUNK/output_fg10/.work"
NPARAMS = {0: 3, 1: 4, 2: 4, 3: 5, 4: 8, 5: 8}


def frame_dir(f): return f"{WORK}/{f:08d}/undistorted"


def names(f): return sorted(os.path.splitext(n)[0] for n in os.listdir(f"{frame_dir(f)}/images"))


def held_out(f): return [n for i, n in enumerate(names(f)) if i % 8 == 0]


def read_cameras(path):
    cams = {}
    with open(path, "rb") as fh:
        for _ in range(struct.unpack("<Q", fh.read(8))[0]):
            cid, model, w, h = struct.unpack("<iiQQ", fh.read(24))
            cams[cid] = (model, w, h, struct.unpack(f"<{NPARAMS[model]}d", fh.read(8 * NPARAMS[model])))
    return cams


def read_images(path):
    """name -> (qvec, tvec, camera id, raw 56-byte pose)."""
    imgs = {}
    with open(path, "rb") as fh:
        for _ in range(struct.unpack("<Q", fh.read(8))[0]):
            fh.read(4); pose = fh.read(56); cid, = struct.unpack("<i", fh.read(4))
            name = b""
            while (c := fh.read(1)) != b"\0": name += c
            n, = struct.unpack("<Q", fh.read(8)); fh.read(24 * n)
            q = np.array(struct.unpack("<4d", pose[:32])); t = np.array(struct.unpack("<3d", pose[32:]))
            imgs[os.path.splitext(name.decode())[0]] = (q, t, cid, pose)
    return imgs


def qrot(q):
    w, x, y, z = q / np.linalg.norm(q)
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def read_ply(path):
    """(header bytes, float32 rows [n, props], property names)."""
    raw = open(path, "rb").read(); end = raw.find(b"end_header\n") + 11
    head = raw[:end].decode("ascii").splitlines()
    n = int([l for l in head if l.startswith("element vertex")][0].split()[-1])
    props = [l.split()[-1] for l in head if l.startswith("property")]
    if any(l.split()[1] != "float" for l in head if l.startswith("property")): raise SystemExit(f"{path}: non-float PLY")
    return raw[:end], np.frombuffer(raw[end:end + 4 * n * len(props)], np.float32).reshape(n, len(props)), props


def write_ply(path, header, rows):
    head = header.decode("ascii")
    old = [l for l in head.splitlines() if l.startswith("element vertex")][0]
    with open(path, "wb") as fh:
        fh.write(head.replace(old, f"element vertex {len(rows)}").encode("ascii"))
        fh.write(np.ascontiguousarray(rows, np.float32).tobytes())


def mask(f, name, down=1, dilate=0.0):
    """The frame's mask of a camera (bool), downscaled by `down`, dilated by `dilate` x sqrt(W*H)
    (eroded when negative)."""
    m = Image.open(f"{frame_dir(f)}/masks/{name}.png").convert("L")
    if down > 1: m = m.resize((m.width // down, m.height // down), Image.BILINEAR)
    m = m.point(lambda v: 255 if v >= 128 else 0)
    r = int(round(dilate * (m.width * m.height) ** 0.5))
    grow = ImageFilter.MaxFilter if r > 0 else ImageFilter.MinFilter
    r = abs(r)
    while r > 0:  # PIL's rank filters take odd sizes; go in steps of at most 7 px
        s = min(r, 7); m = m.filter(grow(2 * s + 1)); r -= s
    return np.array(m) >= 128
