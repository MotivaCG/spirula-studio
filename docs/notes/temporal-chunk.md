# Chunk training (`--temporal-frames`)

Status 2026-09-24, branch `TemporalChunk` (from `Gracia`). Work in progress.

## Why

Per-frame training of a take flickers even when warm-started from the previous
frame (Forge's `ReusePrevious`): every frame is its own optimization, MCMC noise
and relocation reshuffle which splat is which, and each frame fits its own noise.
Measured in Gracia's `tiki.mint` of the same take: one splat population persists
across a whole chunk, scale is frozen for up to 192 frames, and chunk boundaries
carry most splats over. That is a training property, not a codec one.

## Method

One splat population is trained on several frames of a locked rig at once.

- Per frame: position, rotation, opacity, base colour, and their Adam moments.
  Shared: scale and higher-order SH.
- `src/engine/EngineTemporal.cpp` keeps one device slot per frame and swaps it
  into the live buffers before each step (`memcpy_async`, both backends, no new
  kernel), together with that frame's `DataManager`. Each step draws a frame.
- Frames must share cameras bit for bit; frame k's files are frame 0's with the
  dataset root swapped.
- Forced in chunk mode: `quantization_level 0`, no densification,
  `export_keep_all_splats`. One PLY per frame under `frames/NNN/`, same row order
  in every frame (the index is the identity).
- Temporal smoothing every `--temporal-smooth-every` steps, on the host: a
  gradient step on the second time difference for position and rotation
  (constant-velocity motion is free), on the first for opacity and colour.

Flags: `--temporal-frames "dir1;dir2;..."` (frames after `--data`),
`--temporal-smooth-every`, `--temporal-smooth-{position,rotation,opacity,color}`
(0..1), `--temporal-pin-first` (see results: not recommended).

## Measuring

Bench: VIDEOTIKI (105-camera rig, 30 fps), frames 45-76, against Forge's real
chain for the same frames (`.work/<frame>/undistorted/smn`) and Gracia's
`tiki.mint` rendered from our cameras (registered by scaled ICP, cameras moved
into Gracia's frame so its SH need no rotation).

- **Regional render flicker** (the main number): for each fixed camera, 16 px
  block means inside the mask of |d render - d video| between consecutive
  frames, after one colour map per camera. Real motion cancels.
- **Fit**: masked, colour-corrected PSNR on every 8th (trained) camera.
- Subject only (visual-hull prune, matches Forge's take-mask prune to 0.5 %).
- Held-out cameras are useless on this rig: neighbours' background splats sit in
  front of them. The eval loader samples with replacement, so views are matched
  to cameras by content.

Scripts (not in the repo): `outputs/tc/` -- `evaluate.py`, `chain2.ps1`,
`second.ps1`, `gracia_assets.py`, `register.py`.

## Results

Frames 45-50 (one chunk, 8000 steps per frame, from Forge's frame-45 model):

| run | regional flicker | fit dB |
|---|---|---|
| Gracia | 9.1 | (23.2, not comparable: registration) |
| Forge chain | 20.9 | 31.07 |
| chunk, no smoothing | 9.6 | 30.94 |
| chunk, 1st-order smoothing everywhere | 10.6 | 27.13 (motion frozen) |
| chunk, 2nd-order motion smoothing (T3) | **8.4** | 30.39 |

Frames 45-76 (six chunks):

| run | regional flicker | fit dB |
|---|---|---|
| Gracia | 9.5, no spikes (none at its own chunk boundary, frame 64) | |
| Forge chain | 22.4 | 31.0 |
| C1: chunks share a pinned boundary frame | 16.4, spikes 20-56 at boundaries | 28.7, falling 30.6 -> 26.6 |
| C2: + context frame, frozen scale, MCMC noise on | 13.1 | 27.9 |

Second chunk alone (50-55, continuing C2's frame 50):

| variant | fit dB | regional flicker | boundary 50>51 |
|---|---|---|---|
| pinned + frozen scale (C2) | 27.8-28.6 | 13.1 | 16.5 |
| pinned, scale trained | 29.1-29.4 | 8.8 | 9.4 |
| **not pinned, scale trained** | **29.6-30.2** | **6.8** | **8.8** |

## What was learned

- First-order smoothing of motion freezes the subject; smooth acceleration only.
- A chunk's end frames are 6x less constrained by the second difference and
  spike; a context frame past the end, trained and dropped, fixes it.
- Freezing scale after the first chunk costs 2 dB and doubles flicker. Pinning
  the boundary frame costs another 1 dB.
- Without MCMC position noise nearly transparent splats never recover and the
  useful population halves over six chunks; with it, -17 %.
- Seed noise has not been measured for this setup; differences under ~20 % are
  not established.

## Next

1. Chain 45-76 with context frame, no pin, no freeze, noise on (the V2 recipe).
2. Replicates for seed noise.
3. Population refresh at chunk boundaries (relocation of dead splats applied to
   every frame slot) if the fit still decays over long takes.
4. Forge integration, then writing `.vgs` from the per-frame PLYs.
