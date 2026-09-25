# Temporal training (branch `TemporalChunk`) — start here

Entry point for anyone picking this work up on another machine: a person or an
LLM agent. It says what the work is, where it stands, how to build and run it,
and what to do next. The full experiment report, with every number, is
[docs/notes/temporal-chunk.md](docs/notes/temporal-chunk.md). Read this file
first, that one before changing anything.

Repository rules still apply: [AGENTS.md](AGENTS.md), especially the comment
budget (the build fails on comment blocks over 3 lines) and the two-backend rule
(nothing here adds a kernel, on purpose). The owner converses in Spanish; code,
comments and commits are in English.

---

## What this is

Takes captured with a many-camera inward-facing rig (people in the centre) are
normally trained one frame at a time. Played as a sequence they flicker, because
every frame is an independent optimization. This branch trains **several frames
of a take as one splat population**:

- One population for all frames. Per frame: position, rotation, opacity, base
  colour (and their Adam state). Shared: scale and higher-order SH.
- Output: one PLY per frame in which row *i* is the same splat in every frame.
  That identity is what a 4D container (`.vgs` / `.mint`-like) needs.
- Temporal smoothing penalizes acceleration (not motion) and change in opacity
  and colour.

It exists as two modes:

| mode | flags | when |
|---|---|---|
| **Chunk** | `--temporal-frames "d1;d2;..."` | all listed frames trained at once; chain chunks yourself (next chunk starts from the previous chunk's last kept frame, with one extra "context" frame trained and dropped at the end) |
| **Sliding window** | `--temporal-frames ... --temporal-window W --temporal-frame-steps A` | one run walks the whole take: a frame enters every A steps, the oldest is written and then held; no chunk boundaries |

Target reference: Gracia (commercial 4DGS). Their files show the same
principles: persistent splats per ~1 s chunk, fixed scale, and ~10 % of splats
renewed at each boundary.

## Status (2026-09-25)

| | regional flicker ↓ (×1e-3) | fit ↑ (masked PSNR) |
|---|---|---|
| per-frame warm start (the owner's current pipeline) | 22.4 | 31.0 dB, stable |
| Gracia | 9.5 | not comparable |
| **chunk chain, best recipe (C3)** | **7.9** | 30.3 → 27.2 dB over 32 frames |

- **Stability: solved.** Better than Gracia on the test take.
- **Open problem: quality decays through the take.** Splats of the subject die
  as people move: a splat whose surface moved is cheaper to switch off than to
  move. This happens to *any* warm start without births, including the owner's
  per-frame pipeline. It is not caused by chunking. Warps and an opacity boost
  on entry slow it; births are what is missing (see Next).
- Single take and single runs only. Seed noise is unmeasured, so treat
  differences under ~20 % as unproven.

## Build

Needs the normal spirula toolchain (see [AGENTS.md](AGENTS.md) → Building). On
Windows it was built with VS 2022 + CUDA 12.8, CUDA backend, into its own tree so
any other build in use is left alone:

```bat
call "<VS2022>\VC\Auxiliary\Build\vcvars64.bat"
set "CUDA_PATH=<CUDA 12.8 root>"
cmake -G Ninja -B build_tc -DCMAKE_BUILD_TYPE=Release -DSS_BACKEND=cuda ^
      -DSS_BUILD_SAM=OFF -DSS_BUILD_SFM=OFF -DSS_BUILD_GUI=OFF ^
      "-DCMAKE_CUDA_COMPILER=%CUDA_PATH%\bin\nvcc.exe"
cmake --build build_tc -j 14
```

`-DSS_BUILD_GUI=OFF` matters: with SfM off, the GUI still includes `vulkan.h` and
fails without the Vulkan SDK. A clean CUDA build takes about an hour. If
experiments run from the built exe, copy it first; Windows refuses to relink a
running executable.

## Data it expects

One dataset folder per frame (COLMAP layout: `images/`, `masks/`, `sparse/`),
**with camera poses identical across frames** (a locked rig calibration). Frame
k's files are found by swapping the dataset root of frame 0's files, so the
image and mask names must match across frames. Depth and normal folders are
optional, but must exist for every frame or be switched off
(`--load-depths 0 --load-normals 0`).

## Run

A good starting recipe, the one behind C3 (chunks of 6 frames plus 1 context
frame, 8000 steps per trained frame):

```bash
spirula train --data <frame0> --temporal-frames "<frame1>;...;<frame6>" \
  --init-ply <a trained model of frame0>/splat.ply \
  --steps-scaler <frames * 8000 / 30000> \
  --temporal-smooth-every 50 --temporal-smooth-position 1 \
  --temporal-smooth-rotation 1 --temporal-smooth-opacity 1 --temporal-smooth-color 1 \
  --ppisp-from <one PPISP checkpoint for the whole take> \
  [the per-frame flags of your pipeline]
```

Sliding window (the direction going forward):

```bash
spirula train --data <frame0> --temporal-frames "<frame1>;...;<frameN>" \
  --temporal-window 6 --temporal-frame-steps 4000 [--temporal-first-frame-steps 8000] \
  --temporal-warp-dir <folder of NNN.bin warps> --temporal-entry-opacity-boost 2 \
  --init-ply <model of frame0> ...
```

Warps (`NNN.bin`, frame NNN-1 → NNN of `--temporal-frames`) come from
`reference/temporal/warps.py`. It fits a deformation graph between consecutive
frames' sparse clouds, restricted to the subject by the masks. It is a port of
SMNForge's `GraciaWarp`.

Chunk mode forces `quantization_level 0`, turns densification off, and turns
`export_keep_all_splats` on (all needed for per-frame state and identity).
Results land in `<output>/frames/NNN/splat.ply` plus `frames.txt`.

## Evaluating

Hand-run tools in [reference/temporal/](reference/temporal/). They are Python
and PowerShell, on no build path, and their paths are the original machine's, so
edit the constants at the top of each. The ones that matter:

- `evaluate.py` / `quick.py`: fit and regional render flicker, per frame pair;
  `population.py`: live subject splats. All three need `hull.py` and
  `flicker_lib.py`.
- `window.ps1`, `chain3.ps1`, `rchain.ps1`: run experiments; `common.ps1` holds
  the flags.
- Gracia comparison: `mintprobe/` dumps `.mint` frames (build against the
  owner's `mintfile.cpp/h`), `gracia_assets.py` + `register.py` +
  `evalgracia.ps1` render them from your cameras.

Measure the render, not the splats: counting or voxel statistics mislead (see
the report, section 2).

## Next

1. **Births that keep identity**: when a frame enters the window, seed the
   subject points of its sparse cloud that fall in gaps into rows that are dead
   in the frames still training. Cap ~2 % per frame. This is the missing piece
   against the quality decay.
2. Validate on a full take with all three metrics against the per-frame
   pipeline and Gracia; then seed replicates.
3. SMNForge integration: prepare frames without training them, one spirula run
   per segment, pass warps (details in the report, section 6).
4. Write `.vgs` from the per-frame PLYs.
