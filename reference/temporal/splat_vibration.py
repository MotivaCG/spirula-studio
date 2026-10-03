"""Appearance vibration of individual splats, following identity: how much one splat's
luminance and opacity change between frames even when the frame's overall brightness holds.

python splat_vibration.py <run|gracia> ... [--first 45 --last 76]
A run is outputs/tc/<run>/frames/NNN/splat.ply (+ birth_events.tsv for generations); "gracia"
reads tiki.mint through evaluate.gracia_dump (records persist only inside a .mint chunk).
Reports medians and p90 over visible splats (alpha > 0.1) of
  dL1, dA1: |x[t+1] - x[t]|                    frame-to-frame change
  dL2, dA2: |x[t+1] - 2 x[t] + x[t-1]|           its fast part (a smooth trend cancels)
for luminance L (base colour) and opacity A.
"""
import argparse, os
import numpy as np
import evaluate as e
import flicker_lib as fl

TC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "outputs", "tc")


def run_frames(run, frames):
    base = os.path.join(TC, run, "frames")
    out = [fl.ply_frame(os.path.join(base, f"{i:03d}", "splat.ply")) for i in range(len(frames))]
    gen = np.zeros((len(frames), len(out[0]["opa"])), np.int64)
    events = os.path.join(base, "birth_events.tsv")
    if os.path.exists(events):
        for f, r, g in np.loadtxt(events, dtype=np.int64, ndmin=2):
            if f < len(frames):
                gen[f:, r] = g
    # A record is (row, generation): the key keeps reborn rows apart.
    return [(F["col"] @ fl.LUMA, F["opa"], gen[k] * len(F["opa"]) + np.arange(len(F["opa"])))
            for k, F in enumerate(out)]


def gracia_frames(frames):
    out = []
    for f in frames:
        F, alive = e.mint_all(e.gracia_dump(f))
        # Record indices restart in every chunk: tag them with the chunk's record count,
        # which differs between chunks, so no key survives a boundary by accident.
        key = np.where(alive, np.arange(len(alive)) + len(alive) * 10**7, -1)
        out.append((np.clip(F["col"], 0, 1) @ fl.LUMA, np.where(alive, F["opa"], 0), key))
    return out


def vibration(frames):
    d1L, d1A, d2L, d2A = [], [], [], []
    for t in range(len(frames) - 1):
        (L0, A0, k0), (L1, A1, k1) = frames[t], frames[t + 1]
        if len(k0) != len(k1):
            continue
        same = (k0 == k1) & (k0 >= 0) & (A0 > 0.1) & (A1 > 0.1)
        d1L.append(np.abs(L1 - L0)[same]); d1A.append(np.abs(A1 - A0)[same])
        if t == 0:
            continue
        Lm, Am, km = frames[t - 1]
        if len(km) != len(k0):
            continue
        tri = same & (km == k0) & (Am > 0.1)
        d2L.append(np.abs(L1 - 2 * L0 + Lm)[tri]); d2A.append(np.abs(A1 - 2 * A0 + Am)[tri])
    q = lambda xs: (float(np.median(np.concatenate(xs))), float(np.percentile(np.concatenate(xs), 90)))
    return {"dL1": q(d1L), "dL2": q(d2L), "dA1": q(d1A), "dA2": q(d2A)}


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("runs", nargs="+")
    p.add_argument("--first", type=int, default=45)
    p.add_argument("--last", type=int, default=76)
    a = p.parse_args()
    frames = list(range(a.first, a.last + 1))
    print(f"{'run':14s} {'dL1 med/p90':>16s} {'dL2 med/p90':>16s} {'dA1 med/p90':>16s} {'dA2 med/p90':>16s}")
    for run in a.runs:
        v = vibration(gracia_frames(frames) if run == "gracia" else run_frames(run, frames))
        print(f"{run:14s} " + " ".join(f"{v[k][0]:7.4f}/{v[k][1]:7.4f}" for k in ("dL1", "dL2", "dA1", "dA2")))
