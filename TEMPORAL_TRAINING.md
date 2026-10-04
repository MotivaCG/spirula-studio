# Temporal training of takes in spirula — complete handover

Self-contained record of this work, for anyone continuing it on any machine:
a person or an LLM agent. It covers what was built, every experiment (why it was
run, what came out, whether it was kept or reverted and why), how everything was
measured, all paths, and what comes next.

- Repository: `D:\Dependencias\spirula-studio`, branch **`TemporalChunk`** (forked
  from `Gracia`). Commits: `d8fd33d3` (chunk training), `86ee22de` (sliding
  window, warps, cleanup), `73b2e954` and later (this document).
- Owner: Victor (MotivaCG / ScanMeNow / THE4DSCANNER). Conversation in Spanish;
  code, comments and commits in English.
- Repository rules: [AGENTS.md](AGENTS.md). Two bite here: the comment budget
  (the build fails on comment blocks over 3 lines) and the two-backend rule
  (nothing in this work adds a kernel, on purpose).
- Dated 2026-09-25. Everything was measured on **one take with single runs**.
  Seed noise was never measured. The "~20 %" used below is a caution, not a
  measured uncertainty: nothing here is a winner until replicated (section 8).
- **This file is a living log.** Every new experiment is added to section 5,
  every conclusion it changes is corrected in place, and section 8 is kept as
  the current plan. Section 5.4 lists the known weaknesses of what is here.
- **2026-09-27 VGS audit:** executed CPU contracts, export blockers, and the
  staged low-token test handover are in [TEMPORAL_VGS_TEST_PLAN.md](TEMPORAL_VGS_TEST_PLAN.md).
  B8 remains the training candidate; PLY-to-VGS conversion is not validated.

---

## 1. Problem and goal

The owner captures people with a **105-camera inward-facing rig** (SMN_V1
studio). Each frame of a video take is reconstructed and trained as a 3DGS
model by spirula, driven by **SMNForge**. Played in sequence the models flicker:
small regional changes of brightness, boiling detail. **Gracia**, a commercial
4DGS service to which the owner uploads the same takes, returns sequences that
are visibly stable.

Goal set by the owner: *train takes in spirula as stable as Gracia, without
losing quality*. Ideally produce per-frame splats with a persistent identity,
so they can later be written to `.vgs`, the owner's own 4D container.

### Machine it was done on

Windows 11, RTX 4070 (12 GB), 64 GB RAM. VS 2022 (14.44) and VS 18 both
installed; CUDA 12.8 (also 11.x/12.x); Qt 6.8.1 at `C:\Qt\Qt6.8.1\6.8.0\msvc2022_64`.
Python 3.12 at `C:\Python312` with numpy 2.5. **scipy there is broken** (compiled
for numpy 1.x), so every nearest-neighbour search in the tooling uses a numpy
voxel grid instead.

### Paths

| what | path |
|---|---|
| spirula repo | `D:\Dependencias\spirula-studio` |
| build tree for this work | `D:\Dependencias\spirula-studio\build_tc` (never touch `build_temporal_cuda_vs2022`: Forge's registry `Paths/Spirula` points at its `spirula.exe`) |
| experiment outputs (git-ignored) | `D:\Dependencias\spirula-studio\outputs\tc` |
| exe copy the experiments run | `D:\Dependencias\spirula-studio\outputs\tc\bin\spirula.exe` |
| tooling (in repo) | `D:\Dependencias\spirula-studio\reference\temporal` |
| build script used | `reference/temporal` has none; the one used was `...\scratchpad\build_tc.cmd`, reproduced in section 9 |
| test take | `C:\Users\Victor\Documents\Gracia4DGSConverter\VIDEOTIKI` |
| per-frame datasets | `...\VIDEOTIKI\output\.work\000000NN\undistorted` (`images\`, `masks\`, `sparse\`, `smn\step-*.ckpt\splat.ply`, `warped_init.ply` for 46-50) |
| take-wide PPISP | `...\VIDEOTIKI\output\ppisp.ckpt` |
| Forge's published PLYs | `...\VIDEOTIKI\output\000000NN.ply` (take-mask pruned) |
| Gracia's version of the take | `d:\Trabajos\ScanMeNow\SMNWebviewer\Playcanvas\public\data\tiki.mint` (also `content\` and `dist\`) |
| other Gracia samples | `D:\Trabajos\THE4DSCANNER\GraciaScenes\Samples\cycling_clean_300.mint` (25 Hz), `gymnastic_s2_t2_clean.mint` (50 Hz) |
| `.mint` format spec + decoder | `D:\Trabajos\THE4DSCANNER\GraciaConverter\Gracia4DGSConverter\MINT_FORMAT.md`, `mintfile.cpp/h`; self-contained copy used by the probe: `...\Gracia4DGSConverter\build\despill-candidate\mintfile.cpp/h` |
| `.vgs` container | `D:\Trabajos\THE4DSCANNER\VGSFileFormat` (its `FORMAT.md`; the normative decoder is `vgsframe.cpp` in its `core\src`) |
| SMNForge | `D:\Trabajos\ScanMeNow\RaspberrySoft\SMNForge` (branch `GraciaWarp`, commit `97aa162`, has `graciawarp.cpp`; the Profile build `build\Desktop_Qt_6_8_0_MSVC2022_64bit-Profile\release\SMNForge.exe` was used to extract frames 51-76) |
| earlier temporal attempt | spirula branch `DualGSAstra` (its notes are `dualgs.md` in that branch's notes folder): a DualGS-style deformation graph; the owner reports it was "a complete disaster" |
| agent memory of this project | `C:\Users\Victor\.claude\projects\d--Trabajos-FORMS-LichtFeld-Studio\memory\temporal-chunk-training.md` |

---

## 2. What Gracia does (measured from its files)

Why this was studied: to copy the mechanism, not guess it. `tiki.mint` was
decoded with the owner's `MintFile` through a small probe (`reference/temporal/mintprobe`).

- **Chunks** of 32 intervals, about 1 s (30 Hz: 1.067 s). Inside a chunk one
  splat population persists. Position, rotation, opacity and base colour vary
  per sample, and **scale is fixed**. Splats have hard lifetimes: they are born
  and die on interval boundaries.
- **Chunk k+1 continues chunk k.** 88-94 % of visible splats have an exact twin
  across a boundary (< 0.1 mm, same scale). Following them over 4 chunks, the
  scale does not drift (median change 0.3-1.1 %, below the 1.8 % quantization
  step). An independent reconstruction would show about 0 % twins and random
  scales. Conclusion: the persistence comes from training, not from compression.
- **Full reset every ~192 frames** (6 chunks, measured on `gymnastic`): 0 %
  twins and a new splat set with the same bounding box. This looks like
  independent segments, probably trained in parallel.
- **About 10 % of splats are renewed at each chunk boundary** (births and
  deaths). The subject population stays around 165-185k.
- Per splat, colour and opacity jitter almost like noise (roughness of the
  second difference over the first ≈ 1; white noise is 1.73), but the jitter is
  uncorrelated between splats. Whole-body luminance changes only 0.0003-0.0008
  per frame. **What reads as flicker is coherent regional change**, and Gracia
  does not have it.

The earlier VGS encoder rejected non-30 Hz sources. Rechecked 2026-09-27:
current `vgsencode.cpp::setTimebase` derives rational timing from the source.
That implementation is already fixed; built-exporter timebase tests remain in
the VGS test plan. Both non-tiki samples are 25 and 50 Hz.

---

## 3. How it is measured (and which metrics were rejected)

**Bench:** VIDEOTIKI frames 45-76 (32 frames). Camera poses are bit-identical
across frames (locked prior), which chunk training requires; this was verified.

**References:**
- **Forge**: the per-frame models Forge wrote in `.work\NN\undistorted\smn`.
  **Caveat found late:** frames 45-50 use the owner's recipe (init from
  `warped_init.ply`, PPISP frozen from `ppisp.ckpt`, `--refine-start-iter
  99999999` so no densification, `--export-keep-all-splats 1`, lower DC/SH
  learning rates). Frames 51-76 were produced by the newer Forge build during
  this work, with another recipe (`--init-ply` of the previous published PLY +
  `--init-ply-add-points 1`, densification on, `--opacity-boost 1.5`, PPISP per
  frame). Regional flicker is similar for both (20.9 and 22.4); population is
  not.
- **Gracia**: `tiki.mint` at t = frame/30 s, registered to our COLMAP frame by
  scaled ICP between opaque splat centres (`gracia_to_colmap.json`: scale 1.874,
  residual at the sampling-noise level). Our cameras are moved into Gracia's
  frame (camera pose ∘ inverse similarity; scale absorbed into the translation)
  so its degree-3 SH need no rotation. It is rendered by spirula itself.

**Metrics (kept):**

| metric | definition | better |
|---|---|---|
| **Regional render flicker** (main, ×1e-3) | for each fixed camera: 16 px block means inside the mask of \|Δrender − Δvideo\| between consecutive frames, after one affine colour map per camera fitted over all frames. Real motion cancels; what remains is change the render adds (flicker) or misses (motion it did not follow). 10 ≈ 1 % brightness error per region per frame | lower |
| Fit | per-channel affine colour-corrected PSNR inside the mask, on every 8th camera (views that were trained) | higher |
| Subject population | splats with opacity > 0.1 whose centre is inside the visual hull: in the mask of ≥ 90 % of the cameras that see it, ≥ 10 cameras. It reproduces Forge's take-mask prune to 0.5 % | stable |
| Per-splat change | median frame-to-frame change of position (per mille of subject height), luminance, opacity and log-scale of the same row; only when identity holds | — |

**Metrics tried and rejected, and why:**
- **Held-out cameras.** On an inward rig, neighbouring cameras model their
  background with splats that sit right in front of the held-out camera, which
  renders fog (PSNR ~8). The number measured the fog, not the subject.
- **Whole-image PSNR.** The room background dominates it.
- **Voxel luminance/mass change of the splats.** It has a floor that depends on
  splat count and texture (C3 plateaued at 0.0096 whatever the smoothing), so it
  does not measure flicker.
- **Pixel-level render flicker.** Dominated by sensor and compression noise;
  kept as a secondary number only.
- **Counting live splats alone.** An opacity boost inflates it without improving
  the image. It must always be read together with fit and flicker.

**Measurement traps met:** spirula's eval loader samples cameras with
replacement (a camera can be missing or repeated in a frame), so views are
matched to their source image by content (32×56 thumbnails) and the flicker
uses, per frame pair, the cameras present in both frames.

---

## 4. What is in the code (kept)

Files: `src/engine/EngineTemporal.{h,cpp}` (new), hooks in
`src/app/TrainerCore.{h,cpp}`, rows in `src/config/TrainConfig.h`, help texts in
`src/i18n/catalog/TrainFields.h` (English-only `SS_MSG_EN`).

- **Chunk training** — `--temporal-frames "dir1;dir2;..."` (the frames after
  `--data`). One population. Per frame: means, quats, opacities, features_dc,
  their Adam moments and the per-splat bias-correction steps, held in one device
  slot per frame and swapped into the live buffers before each step with
  `memcpy_async` (both backends, no new kernel), together with that frame's
  `DataManager` (`engine().dm`). Shared: scale and higher-order SH.
  - Frame k's files are frame 0's with the dataset root swapped.
  - Forced: `quantization_level 0` (fp32 moments to copy), no densification
    (`refine_start_iter` past the end; relocation kernels do not report their
    mapping), `export_keep_all_splats`.
  - Adam state is pre-allocated at begin, with `engine_ensure_optim_state`,
    because it is otherwise allocated lazily on the first step.
  - Output: `frames\NNN\splat.ply` plus `frames.txt`, same row order in every
    frame. `eval()` scores each frame against its own images, and
    `--save-eval-images` writes the renders plus `eval_views.txt` next to each
    frame's metrics.
- **Temporal smoothing** — every `--temporal-smooth-every` steps, on the host.
  It is a gradient step on the 2nd time difference for position and rotation
  (constant velocity is not penalized; quaternions are sign-aligned and keep
  their norm), and on the 1st difference for opacity (in **opacity** space) and
  base colour. Weights `--temporal-smooth-{position,rotation,opacity,color}` in
  [0, 1]; 1 is a step of 1/top eigenvalue.
- **Sliding window** — `--temporal-window W --temporal-frame-steps A`
  (+ `--temporal-first-frame-steps`, `--temporal-history`).
  - A frame enters every A steps. The first frame may train longer on its own
    first (owner's idea: more iterations at the start of a chunk, fewer after).
  - When the window is full, the oldest trainable frame is written and
    **held**: not trained, but its neighbours are smoothed towards it. So there
    are no chunk boundaries.
  - Each frame runs its own learning-rate and MCMC-noise schedule by its own
    age (`build_step_config` and the engine get the frame's age, not the global
    step).
  - An entering frame is the previous one moved by a **warp**
    (`--temporal-warp-dir`) or, without one, by constant-velocity
    extrapolation. `--temporal-entry-opacity-boost` multiplies its opacities.
  - `num_iterations` is derived: first + A·(n + W − 2).
- **Warps** — `NNN.bin` per frame (deformation graph from frame NNN−1 to NNN of
  `--temporal-frames`: int32 node count, float32 skinning radius, rows
  `[g xyz, t xyz, q wxyz]`). They are computed by
  `reference/temporal/warps.py`, a numpy port of Forge's `GraciaWarp`:
  - ~4000 nodes sampled on the previous frame's sparse cloud, **restricted to
    the subject** by the visual hull;
  - ARAP with local rotations by SVD and Jacobi translation sweeps;
  - correspondences to the next frame's cloud within 5 cm.

  spirula skins each splat to its 4 nearest nodes with Gaussian weights and
  blends the node rotations into the splat's rotation.

---

## 5. Every experiment

Common setup unless noted: the owner's per-frame flags
(`reference/temporal/common.ps1`: `--sh-degree 1 --cap-max 395204
--min-opacity 0.01 --mask-boundary-offset 0.03 --darkness-boost 2
--background-mode sh --use-ppisp 1 --ppisp-from ppisp.ckpt
--export-keep-all-splats 1 --sh-decay 0.04 --overexposure-reg 10`, depth and
normals off because only frame 45 has them) plus the warm extras
(`--init-ply-add-points 0 --refine-start-iter 99999999 --opacity-reg 0
--features-dc-lr 0.0005 --features-sh-lr 0.000025`). Init = Forge's model of
the first frame.

### 5.0 Earlier, before this branch (context)
- **Per-frame warm start (Forge `ReusePrevious`).** A little better than
  independent frames and faster, but with small luminosity changes (owner). It
  is the baseline.
- **Take-wide PPISP (`--ppisp-from`).** The owner had already added it; it
  helps, but "it is not enough" (owner). Kept in every run here.
- **DualGS-style tracking** (spirula branch `DualGSAstra`). A "complete
  disaster" per the owner: severe brightness flicker; its own notes suspect PPISP
  and publication pruning re-done per frame.

### 5.1 Single chunk, frames 45-50, 8000 steps per frame

Why: does training frames jointly reduce flicker by itself, and what smoothing
does it need?

| run | change | regional flicker | fit dB | per-splat Δopacity / Δpos |
|---|---|---|---|---|
| Gracia | — | 9.1 | (23.2, bound by registration) | 0.007 / 2.0‰ |
| Forge | — | 20.9 | 31.07 | identity broken: scale ×2.5 per frame for the same row |
| T1 | chunk, no smoothing | 9.6 | 30.94 | 0.10 / 8.2‰ |
| T2 | 1st-order smoothing on everything, 0.25 | 10.6 | **27.13** | 0.007 / 0.02‰ |
| **T3** | 2nd-order motion smoothing, weight 1 | **8.4** | 30.39 | 0.005 / 1.8‰ |
| T4 | T3 with 12000 steps/frame | 10.3 | 30.57 | — |
| T5 | T3 with weights 0.5 | 10.7 | 30.55 | — |

Verdict:
- **Joint training alone halves flicker vs Forge.**
- 1st-order smoothing of motion **rejected**: it freezes the subject (T2),
  because a Laplacian flattens every trajectory over hundreds of passes.
- 2nd-order smoothing **kept**: it only penalizes acceleration, so real motion
  survives (1.8‰ vs Gracia's 2.0‰).
- T3/T4/T5 differences are within noise.

### 5.2 Chains of chunks, frames 45-76

Why: a take is longer than a chunk; how do boundaries behave?

| run | recipe | regional flicker | fit dB (start → end) |
|---|---|---|---|
| C1 | 6-frame chunks, next chunk **pins** the shared boundary frame (`--temporal-pin-first`), scale trained, MCMC noise **off** | 16.4, spikes 20-56 at every boundary | 30.6 → 26.6 |
| C2 | + 1 **context frame** trained past the end and dropped, **scale frozen** after the first chunk (`--scales-lr 0`), MCMC noise on | 13.1 | 30.3 → 26.0 |
| **C3** | context frame, boundary frame **not pinned** (trained again), scale trained, noise on | **7.9** (Gracia 9.5, Forge 22.4) | 30.3 → **27.2** |

Second chunk alone (frames 50-55, continuing C2's frame 50), to separate causes:

| variant | fit dB | regional flicker | boundary pair 50>51 |
|---|---|---|---|
| pinned + frozen scale (C2) | 27.8-28.6 | 13.1 | 16.5 |
| V1: pinned, scale trained | 29.1-29.4 | 8.8 | 9.4 |
| **V2: free, scale trained** | **29.6-30.2** | **6.8** | **8.8** (Gracia 8.2) |

Verdict:
- The end frames of a chunk get about 6× less constraint from the 2nd difference
  and spike. The **context frame** fixed it (kept, in `chain3.ps1`).
- **Freezing scale rejected** (−2 dB, flicker ×2 in V1 vs C2). That Gracia can
  freeze scale *because* it also has births is a plausible hypothesis, not a
  result.
- Attribution is partial: C1 → C2 changed context frame, scale and noise at
  once, C2 → C3 pinning and scale. V1/V2 separate pinning from freezing on one
  chunk only. C3's overall gain is measured; each component's share is not.
- **Pinning rejected** (−1 dB): later removed from the code; the window's held
  frames replace it.
- MCMC noise off **rejected**: the population halved over six chunks.
- **C3 is the best stability result.** In pairs where both are free of
  boundaries it beats Gracia (5-7 vs 6-8).

### 5.3 Why fit decays: the subject's splats die

Why: C3 loses 3 dB over 32 frames while Forge stays at 31.

Subject population in C3 went from 134k to 49k; the background stayed ~55k.
Forge's subject sits around 170k and Gracia's around 170k. The loss is on the
people.

**Diagnosis D0-D6** (frames 50-56, 4000 steps/frame, start at 133.7k): which
part kills splats?

| run | change | frame 50 | frame 56 |
|---|---|---|---|
| D4 | single frame, spirula's normal path (control) | 145.8k (+9 %) | — |
| D5 | D4 with `--quantization-level 0` | 146.4k | — |
| D6 | D4 repeated with the new exe | 144.7k | — |
| D3 | chunk, no smoothing | 141.8k | 115.6k |
| D2 | no motion smoothing | 125.6k | 120.8k |
| D0 | all smoothing (C3 recipe) | 110.8k | 108.8k |
| D1 | no opacity smoothing | 126.0k | 104.4k |

It showed two effects: smoothing costs ~15k everywhere, and frames far from
their initial copy lose more. fp32 is not the cause (D5).

**Sliding windows on 50-60** (W=6 unless noted, 4000 steps per frame, init
Forge frame 50 = 131.6k). Each run tests one hypothesis:

| run | hypothesis tested / change | 50 | 60 | 50→60 | verdict |
|---|---|---|---|---|---|
| W1 | window over 45-76 (8000 steps, full smoothing) | 129k | 59k (at 76) | — | same death as C3 → not caused by chunk boundaries |
| Wa | motion smoothing weakened to 0.25 | 109k | 92k | −16 % | smoothing is not the root cause |
| Wb | no motion smoothing | 114k | 94k | −18 % | same |
| Wd | no smoothing at all | 125k | 82k | −34 % | worse: smoothing was not the killer |
| We | colour smoothing only | 125k | 78k | −37 % | same |
| Wf | fresh Adam moments per entering frame (Forge restarts Adam each frame) | 125k | **48k** | −62 % | **rejected**, code removed |
| Wg | entry opacity boost ×1.5 (owner's idea) | 125k | 113k | −10 % | helps |
| Wh | Wg + split rebirth | 125k | 105k | −16 % | rebirth **rejected**, code removed |
| **Wj** | entry opacity boost ×2 | 127k | 121k (139k at 54) | **−4 %** | best so far (fit/flicker not yet measured) |
| Wk | per-frame scale (shared scale suspected) | 127k | 81k | −37 % | **rejected**, code removed |
| Wl | per-frame scale + boost 1.5 | 127k | 112k | −12 % | = Wg |
| Wn | MCMC noise on the frame's own schedule (bug: late frames got ~65× less noise) | 124k | 81k | −35 % | bug fixed and kept, no effect |
| Wo | Wn + boost 1.5 | 125k | 114k | −9 % | = Wg |
| Wp | window of 1 (is interleaving frames the cause?) | 129k | 65k | −49 % | no: one frame at a time dies too |
| Wq | window of 1 + fresh moments | 127k | 41k | −68 % | rejected |
| Wr | window of 1 with auxiliary schedules scaled like D5 (`--steps-scaler 0.1333`) | 128k | 65k | −49 % | warmup schedules are not the cause |
| Ws | window 6 + **warp** (GraciaWarp port) | 124k | 100k | −20 % | warp helps (kept) |
| Wu | window 1 + warp | 128k | 91k | −29 % | warp helps |

**Controls without any temporal code**, a plain chain through spirula's normal
path with init = the previous frame's PLY:

| run | change | 50 | 54 | 60 |
|---|---|---|---|---|
| R1 | 4000 steps per frame | 128k | 98k | 72k (−43 %) |
| R2 | 12166 steps per frame (Forge's count) | 125k | 89k | — |
| Forge, owner's recipe (46-50) | warped init | 192k (46) | — | 132k (50) |
| Forge's `warped_init.ply` for 46-50 | — | carries exactly the previous frame's population; adds nothing | | |

**Current reading (not yet proven, see 5.4).** Chunk or window training is not
the only cause: every warm start without births lost subject splats here,
**including the owner's own pipeline** (R1, R2, Forge 46-50). The working
hypothesis is that, for the optimizer, switching off a splat whose surface moved
is cheaper than moving it.
- Smoothing (logit-space opacity especially) and missing warps accelerate it.
- Warps and an opacity boost on entry slow it, **as counted by opacity > 0.1**.
  The boost raises opacities directly and may raise the count without restoring
  surface or detail; Wj and Ws have no fit or flicker numbers yet.
- Births are what the populations that stay stable have in common: Gracia's
  per-chunk refresh, the newer Forge recipe's `--init-ply-add-points 1` plus
  densification (~175k).
- Not separated yet: death from following motion vs death from re-optimizing
  the same content over and over. The repeated-frame control (5.4) does that.

### 5.5 Battery B1: full metrics on existing runs, frames 50-60 (2026-09-25)

No new training: evaluation of existing artifacts with added metrics. **Detail**
= masked PSNR of the high frequencies (image minus a 7 px box blur) after the
same colour map as fit. **Coverage** = share of the frame's SfM subject points
with a splat of opacity > 0.1 within 1 cm. Population is given at three
opacity thresholds.

| run | fit dB | detail dB | regional flicker | live k >0.02/>0.1/>0.5 at 50 → 60 | coverage 50 → 60 |
|---|---|---|---|---|---|
| Gracia | (23.0) | (32.2) | **7.77** | — | — |
| Forge | **30.95** | **36.71** | 19.17 | 155/131/60 → 328/181/14 | 90 → 94 % |
| R1 plain chain | 29.53 | 34.99 | 21.22 | 152/127/58 → 84/72/39 | 90 → 81 % |
| Wd window, nothing | 29.86 | 35.21 | 19.71 | 147/125/59 → 98/82/43 | 89 → 86 % |
| Wg + boost ×1.5 | 29.95 | 35.13 | 18.88 | 146/125/61 → 131/113/79 | 89 → 85 % |
| Wj + boost ×2 | 29.55 | 35.00 | 20.89 | 147/126/62 → 139/121/92 | 90 → 85 % |
| **Ws + warp** | **30.13** | **35.35** | **10.94** | 150/124/58 → 116/99/50 | **89 → 88 %** |

(These W runs have no temporal smoothing; Forge here is the newer recipe from 51.)

What it shows:
- **The entry opacity boost does not restore surface.** It raises counts
  (Wj: 92k above 0.5) with the same coverage as Wd and slightly worse fit and
  flicker. Rejected as a quality fix; the earlier "Wj best" came from the count.
- **Most of the "death" is dimming or redundant splats, not lost surface**: Wd
  loses 34 % of the >0.1 count but coverage only 89 → 86 % and fit does not
  fall over this span.
- **The warp is the real gain**: it halves the window's flicker (19.7 → 10.9)
  and keeps coverage and the best fit/detail of our runs. Gracia is still ahead
  on flicker in this span (7.8).
- We are ~1.4 dB below Forge in detail.

Not shown: whether the warp's gain holds with smoothing on and over 32 frames;
why C3's fit decays over 45-76 (the window runs here do not decay over 11
frames); seed spread.

### 5.6 Battery B2: repeated-frame control (2026-09-25)

Hypothesis: if frame 50 repeated as a motionless sequence also loses subject
splats, part of the loss comes from re-optimizing, not from motion. Same init
(Forge frame 50), same flags, no smoothing.

| run | motion | live k >0.02/>0.1/>0.5, 50 → 60 | coverage 50 → 60 |
|---|---|---|---|
| RF1 window W6, frame 50 ×11 | no | 150/125/59 → 124/105/52 (−16 % at >0.1) | 90 → 89 % |
| Wd same window, real frames | yes | 147/125/59 → 98/82/43 (−34 %) | 89 → 86 % |
| RF3 plain chain, frame 50 ×11 | no | 152/127/58 → 120/102/53 (−20 %) | 90 → 87 % |
| R1 same chain, real frames | yes | 152/127/58 → 84/72/39 (−43 %) | 90 → 81 % |
| RF2 frame 50, 64k steps continuous | no | 155/131/60 → 134/118/65 (−10 %) | 90 → 89 % |

What it shows: about half of the count loss happens without motion, from
re-optimizing (the criterion set before the run was "≥ half → re-optimization
is a main cause"; it lands at ~47 %, on the edge). But **that half costs almost
no coverage**: it is redundant splats consolidating. The **loss of covered
surface comes with motion** (coverage 89-90 → 81-86 % only with real frames).
Decision: go on to births, judged by coverage, fit, detail and flicker, not by
counts.

Not shown: whether the re-optimization dimming costs fit over longer takes.

### 5.7 Battery B3: births that keep identity, frames 50-60 (2026-09-25)

Code: `engine_temporal_birth` (`--temporal-birth-dir/-gap/-fraction`). When a
frame enters the window, its subject SfM points (`births.py`: hull-filtered,
colour, spacing to the 4th neighbour, median ~17 mm) with no live splat within
1 cm take rows whose opacity is < 0.005 in **every** frame, held ones included
(so no frame already trained or written changes): position of the point,
identity rotation, colour of the point, scale half the spacing, opacity 0.1 in
the entering frame only (dead in every earlier one), no optimizer history. Cap
2 % per frame; 800-1500 were born per frame.

Audit correction (2026-09-27): the `<0.005` criterion is not exact absence.
The CPU tests in `TEMPORAL_VGS_TEST_PLAN.md` show that earlier in-memory slots
are modified and can remain above the raster cutoff; older optimizer moments
also survive. Disk PLYs already written are unchanged. Generation/lifetime
semantics and GPU render invariance still need validation before VGS export.

Window W6, 4000 steps, warp on, no smoothing. Criterion set before the run
(vs Ws): coverage at 60 ≥ +2 points, fit and detail not below by > 0.2 dB,
flicker not above by > 15 %.

| run | fit dB | detail dB | regional flicker | live >0.1 50 → 60 | coverage 50 → 60 | verdict |
|---|---|---|---|---|---|---|
| Ws warp (B1) | 30.13 | 35.35 | **10.94** | 124k → 99k | 89 → 88 % | reference |
| B3b + boost 1.5 | 30.09 | 35.30 | 14.76 | 125k → 137k | 89 → 88 % | fails: +35 % flicker, no coverage |
| B3c + births | 30.13 | 35.38 | 13.18 | 123k → 107k | 89 → **92 %** | fails flicker (+20 %) |
| **B3d + births + boost 1.5** | 30.08 | 35.34 | 11.45 | 124k → 142k | 89 → **91 %** | **passes** |

What it shows: births restore covered surface lost to motion (+3-4 points)
with no cost in fit or detail. Over 11 frames that surface does not show in
fit yet. B3d passes the flicker criterion and B3c does not, but 11.45 vs 13.18
is one run each: not established.

Not shown: whether covered surface holds fit over a full take (C3 fell to
27.2 dB), the effect with smoothing on, seed spread. Next: battery B4.

### 5.8 Battery B4: the B3d recipe over the whole take 45-76 (2026-09-25)

Window W6, 4000 steps per frame, first frame 8000, warp + births + entry boost
1.5; B4b adds smoothing (every 50, weights 1). Criterion set before (vs C3):
fit at 76 ≥ 29.5 dB and mean ≥ C3's, coverage at 76 ≥ 85 %, flicker ≤ 9.5.

| run | fit mean (45 / 76) | detail | regional flicker | coverage 45 / 60 / 76 | live >0.1 45 / 76 |
|---|---|---|---|---|---|
| Gracia | (23.12) | (32.12) | 9.49 | — | — |
| Forge | **30.99** (31.5 / 31.0) | **36.68** | 22.39 | 65 / 94 / 94 % | 167k / 180k |
| C3 | 29.11 (30.3 / 27.2) | 34.63 | **7.87** | 62 / 81 / **55 %** | 134k / 48k |
| **B4a** | **30.15** (31.6 / **30.0**) | 35.53 | **25.14** | 65 / 93 / **91 %** | 183k / 163k |
| B4b + smoothing | 29.80 (30.5 / 29.4) | 35.12 | 22.95 | 66 / 93 / 85 % | 170k / 120k |

(Coverage at 45 is ~65 % for everyone: that frame's SfM subject cloud is
larger than the others'.)

What it shows: **the quality decay is solved**: births + warp hold ~30 dB and
91 % coverage to the end of the take (C3 fell to 27.2 dB and 55 %). But
**flicker fails**: 25, worse than Forge. It is concentrated in pairs 49-65
(35-61 per pair, C3 4-9 there) and back to 9-14 from 66. B3d on 50-60 had
7-23 per pair. Neither images, masks, SfM clouds nor warps change around
frame 50 (checked), so the dataset switch at 50/51 is not the cause.
Suspect: the entry opacity boost (B3b: +35 % flicker alone), worst where the
subject is still. Battery B5 isolates it.

### 5.9 Battery B5: where B4a's flicker comes from, frames 45-64 (2026-09-26)

Same window as B4a (first frame 8000, warps and births from 45), one change
each. B4a's frames 45-64 are reused (they were written before later frames
entered).

| run | fit | detail | regional flicker | coverage 64 | live >0.1 at 64 |
|---|---|---|---|---|---|
| C3 (chunks, smoothing) | 29.86 | 35.05 | **6.20** | 79 % | 79k |
| B4a warp + births + boost | 30.31 | 35.68 | 30.44 | 92 % | 205k |
| **B5a warp + births** | **30.58** | **35.89** | 15.45 | **93 %** | 130k |
| B5c warp only | 30.55 | 35.83 | 14.53 | 91 % | 122k |

What it shows: **the entry opacity boost caused half the flicker** (30 → 15)
and is dropped from the recipe. **Births add no flicker** (B5a ≈ B5c) and give
the best quality of all runs. The remaining gap to C3 (15 vs 6) coincides with
the one thing C3 has and these windows lack: temporal smoothing. Battery B6.

Not shown: whether smoothing closes the gap without costing coverage (B4b
had smoothing but also the boost).

### 5.10 Battery B6: smoothing on the window, frames 45-64 (2026-09-26)

B5a recipe plus smoothing (weights 1, every 50 or every 25 steps).

| run | fit | detail | regional flicker | coverage 64 |
|---|---|---|---|---|
| B5a no smoothing | 30.58 | 35.89 | 15.45 | 93 % |
| B6a every 50 | 30.40 | 35.54 | 16.51 | 92 % |
| B6b every 25 | 30.12 | 35.35 | 17.43 | 92 % |

What it shows: smoothing does not reduce the window's flicker (and costs a
little fit); isolated pairs spike to 30-43, at different pairs in each run.
Fails the criterion.

Found afterwards, with no GPU: **in the window the shared scale of a splat
changes ~15 % between consecutive written frames** (median |Δ log scale|,
B5a), because each frame is written at a different time while scale keeps
training. Inside a C3 chunk it is exactly 0 (all frames written together); it
jumps 36-61 % only at C3's chunk boundaries, which are exactly C3's slightly
worse pairs (8-9 vs 5-6). Per-frame smoothing cannot touch it: scale is shared.
Battery B7 tests freezing or slowing scale in the window.

### 5.11 Battery B7: slowing the shared scale in the window, frames 45-64 (2026-09-26)

B5a recipe (warp + births, no boost, no smoothing) with scale frozen or its
learning rate divided by 10.

| run | fit | detail | regional flicker (per pair) | coverage 64 |
|---|---|---|---|---|
| C3 (reference) | 29.86 | 35.05 | 6.20 | 79 % |
| B5a scale normal | 30.58 | 35.89 | 15.45 (spikes to 43) | 93 % |
| B7a scale frozen | 30.34 | 35.67 | 7.63 (5-12) | 92 % |
| **B7b scale lr / 10** | **30.96** | **36.05** | **7.24 (5-9)** | **92 %** |

(Forge on this span: fit ~31.0, detail ~36.7.)

What it shows: **the shared-scale drift was the window's remaining flicker.**
Slowing scale halves flicker and removes the spikes, with no quality cost:
B7b matches Forge's fit, is 0.6 dB below its detail, keeps the covered surface
and is as stable as C3. **B7b is the candidate recipe.** Freezing scale fully
(B7a) also works, slightly worse on fit. (This also revises 5.2: freezing scale
cost fit in the chunk chain, where there were no births.)

Not shown: the full take, seed spread. Battery B8.

### 5.12 Battery B8: candidate B7b over the whole take, twice (2026-09-26)

Recipe: window W6, 4000 steps per frame, first frame 8000, warp + births,
`--scales-lr 0.002 --scales-lr-final 0.0005`, no boost, no smoothing. Two
identical runs (spirula seeds its sampling from the clock, so reruns differ).
Criterion set before: both runs fit mean ≥ 30.5 and at 76 ≥ 30.0, coverage at
76 ≥ 88 %, flicker ≤ 9.5, and the two runs within 10 % of each other.

| run | fit mean (45 / 76) | detail | regional flicker | coverage 45 / 60 / 76 | live >0.1 45 / 76 |
|---|---|---|---|---|---|
| Forge | **30.99** (31.5 / 31.0) | **36.68** | 22.39 | 65 / 94 / 94 % | 167k / 180k |
| Gracia | (23.12) | (32.12) | 9.49 | — | — |
| C3 | 29.11 (30.3 / 27.2) | 34.63 | 7.87 | 62 / 81 / 55 % | 134k / 48k |
| **B8a** | **30.86** (31.8 / 30.5) | 35.90 | **7.73** | 64 / 93 / **91 %** | 166k / 106k |
| **B8b** | **30.81** (31.7 / 30.6) | 35.91 | **8.87** | 63 / 92 / **91 %** | 163k / 105k |

What it shows: **the candidate holds over the whole take.** Both runs are
below Gracia's flicker and ~3× below Forge's, within 0.2 dB of Forge's mean fit.
The final-frame gap is 0.4-0.5 dB (30.5/30.6 at frame 76 versus Forge's 31.0,
where C3 had fallen to 27.2), keeping
the covered surface. Fit agrees between runs to 0.2 %. **Flicker differs by
15 % between two identical runs**: the first measured seed spread, and the
only criterion not met (10 % was the guess). Remaining gap: ~0.8 dB of detail
below Forge. GIF: `outputs\tc\B8a_45_76.gif` (half size `..._small.gif`), camera
H2_P10, video | Forge | B8a | Gracia.

Sequence for playback: `D:\Dependencias\spirula-studio\outputs\tc\sequences\B8a\`
with `0045.ply` ... `0076.ply` (unpruned, COLMAP frame, SH degree 1).

**B8 is the current recipe** (section 4 flags; `window.ps1 ... 6 4000
--temporal-first-frame-steps 8000 --temporal-warp-dir ... --temporal-birth-dir
... --scales-lr 0.002 --scales-lr-final 0.0005`).

Not shown: robustness on another take; a uniform Forge baseline; the detail
gap's cause; more seeds.

### 5.13 Battery B9: detail candidates, frames 45-64 (2026-09-27)

The three runs completed; full metrics and manifests are in
`outputs/tc/B9_20260927_battery`. Same B8 recipe except the stated change.

| run | fit mean / final dB | detail dB | flicker | coverage at 64 | training time |
|---|---|---|---|---|---|
| control | 30.969 / 30.901 | 36.056 | 9.834 | 92.38% | 25:18 |
| 8000 steps/frame | 31.380 / 31.486 | 36.246 | 7.316 | 92.06% | 43:33 |
| SH learning rate x2 | 31.044 / 31.017 | 36.120 | 7.725 | 92.60% | 23:51 |

8k is promising for fit (+0.411 dB mean), at 72% more measured training time.
Its detail gain (+0.190 dB) misses the predeclared >=0.2 dB promotion threshold;
SH x2 gains only 0.064 dB detail. Neither is promoted. Flicker comparisons are
single-run observations; the control has early pair spikes around 34. B8 remains
the reference. The three B8R repetitions were still pending/in progress when this
entry was written. See section 7 of `TEMPORAL_VGS_TEST_PLAN.md` for interpretation
and actions. VGS lifetime/representation validation remains outstanding.

### 5.14 Batteries FC3-FC5, R, R2X: Forge chunks through `.vgs` (2026-10-02/03)

Forge's chunk path (SMNForge `GRACIA_CHUNK_TRAINING.md`) on 45-76, published
frames encoded by VGSFileFormat's `vgsplyseq` (encoding 0, one 31-frame chunk):

| run | fit | detail | flicker | MB / 31 frames |
|---|---|---|---|---|
| FC4 published (lock + opacity/colour smoothing) | 24.28 | 34.60 | 9.52 | — |
| FC4 `.vgs` | 23.27 | 32.87 | 15.31 | 24.9 |
| FC5 published (+ position/rotation 2nd order) | 24.05 | 34.29 | 10.31 | — |
| FC5 `.vgs` | 23.76 | 33.59 | 11.49 | 24.6 |

Training jitter is what the codec cannot keep: FC5 cuts its error from
11.8 mm / 20 deg to 3.9 mm / 7.5 deg. R2X (one attribute exact at a time on
R1's `.vgs`): with the position model reused, rotation was the largest
remaining loss (+0.24 dB, -1.1 flicker), opacity and colour ~0.5 flicker each.
Refining on the codec's positions (`--temporal-init-dir`, visible set fixed)
helped FC4's codec positions but not FC5's (23.61 / 12.44): dropped.
Per-splat vibration, `splat_vibration.py`, median second difference vs Gracia:
luminance 0.0004 vs 0.0018, opacity 0.0123 vs 0.0032 — opacity is what is left.

### 5.15 Batteries OB, OC, CX, DX5, PS, FC6, RB: what `.vgs` still loses (2026-10-03/04)

Scripts in `outputs/tc/battery_<name>.ps1`. OB and OC run spirula alone on 45-76
with FC5's recipe (warps/births from `warps45`/`births45`, no depth, no prune);
the rest work on FC5's or FC6's Forge output.

**OB: an L1 band on each written frame's opacity change** (4DGCPro's rate
penalty, as a proximal step: the change since the previous frame shrinks by the
band, smaller changes vanish, nothing crosses 1/255). Rejected and reverted:

| run | band | fit raw | flicker raw | fit `.vgs` | flicker `.vgs` | dA2 med / p90 |
|---|---|---|---|---|---|---|
| OB0 | 0 | 29.83 | 11.64 | 28.47 | 17.34 | 0.0116 / 0.0375 |
| OB1 | 0.01 | 29.58 | 11.93 | 28.20 | 19.64 | 0.0069 / 0.0305 |
| OB2 | 0.02 | 29.25 | 16.26 | 27.90 | 26.96 | 0.0035 / 0.0273 |
| OB3 | 0.04 | 28.62 | 17.46 | 27.27 | 27.79 | 0.0000 / 0.0216 |

OB2 matches Gracia's per-splat opacity vibration (0.0032) and flickers 40 %
more: the following frames compensate the frozen one with larger changes.
**The per-splat vibration median does not predict rendered flicker**; it is a
diagnostic, decisions go by rendered flicker.

**OC: smoothing strength**, one part stronger at a time against OB0. None wins:

| run | change | fit raw | flicker raw | fit `.vgs` | flicker `.vgs` | codec error |
|---|---|---|---|---|---|---|
| OB0 | — | 29.83 | 11.64 | 28.47 | 17.34 | 9.6 mm / 6.8 deg |
| OC1 | position/rotation weight 2 | 29.65 | 11.63 | 28.45 | 19.84 | 8.2 mm / 5.7 deg |
| OC2 | every 50 steps | 29.34 | 13.03 | 28.22 | 19.49 | 7.9 mm / 5.9 deg |
| OC3 | opacity/colour weight 2 | 29.54 | 11.76 | 28.21 | 21.01 | 9.7 mm / 7.0 deg |

Unpruned spirula runs give spiky per-pair `.vgs` flicker (single pairs of
30-47), so differences of 2-4 here are within noise; Forge's pruned output gives
a smooth curve. `.vgs` decisions are taken on Forge output.

**CX: the codec's own settings** on FC5's published frames:

| run | setting | fit | flicker | first pair | MB / 31 frames |
|---|---|---|---|---|---|
| FC5 `.vgs` | residual rotation, 0.5 mm / 2 deg, 16384 atoms | 23.76 | 11.49 | 14.1 | 24.6 |
| CX1 | rotation as samples (0.12 deg error) | 23.80 | 11.36 | 13.7 | 45.2 |
| CX2 | rotation tolerance 1 deg | 23.75 | 11.49 | 14.1 | 24.6 |
| CX3 | position tolerance 0.25 mm | 23.76 | 11.51 | 13.9 | 24.7 |
| CX4 | 32768 position atoms | 23.79 | 11.39 | 13.9 | 28.1 |

**DX5: one attribute exact** (one encode, `--export-exact`):

| exact | fit | flicker | first pair |
|---|---|---|---|
| none (FC5 `.vgs`) | 23.76 | 11.49 | 14.1 |
| position | 24.01 | 10.42 | 10.0 |
| colour DC | 23.76 | 11.49 | 14.1 |
| opacity | 23.76 | 11.52 | 14.1 |
| scale + SH | 23.76 | 11.48 | 14.1 |
| all but position | 23.80 | 11.41 | 13.7 |
| (FC5 published) | 24.05 | 10.31 | 9.4 |

**Position is ~95 % of the codec's loss**, including the first pair (frame 0:
5.5 mm against 3.7 mm for the others). Almost every record already uses the four
terms encoding 0 allows (ranks 2070 / 8317 / 6732 / 314928), which is why
tolerances and more atoms barely help.

**PS: splitting records** whose decoded position strays past a bound
(`--max-position-error`):

| bound | fit | flicker | first pair | records | MB / 31 frames |
|---|---|---|---|---|---|
| none | 23.76 | 11.49 | 14.1 | 332047 | 24.6 |
| 20 mm | 23.79 | 11.21 | 12.6 | 364327 | 25.76 |
| 10 mm | 23.82 | 11.09 | 11.8 | 484727 | 30.3 |
| 6 mm | 23.86 | 10.94 | 10.8 | 890618 | 45.8 |

**FC6: Forge with position smoothing weight 2** (rotation 1). Codec error
3.9 → 3.3 mm, but training lost what the codec gained: published 24.04 / 10.54
(FC5 24.05 / 10.31), `.vgs` 23.78 / 11.53, with 20 mm splits 23.81 / 11.32 at
25.3 MB. Reverted.

**RB: the joint refine on codec positions, on Forge's own work folders** with
PPISP learned in the run (FC5's refine had trained on the VIDEOTIKI take with
its frozen PPISP). Better than FC5's refine, still worse than not refining:
RB1 23.78 / 11.95 (`.vgs` 23.73 / 12.14); RB2, half the appearance rates,
23.67 / 12.48. Appearance cannot make up for position error: the refine path is
closed.

**Current best: FC5's recipe in Forge, encoded with `vgsplyseq --rotation
residual --max-position-error 20`.**

| | fit | detail | flicker | size |
|---|---|---|---|---|
| Forge per frame, published | 24.76 | 35.48 | 12.69 | not compressible in time |
| Gracia | — | — | 9.49 | ~31 MB / chunk |
| FC5 published | 24.05 | 34.29 | 10.31 | — |
| **FC5 `.vgs`, 20 mm splits** | **23.79** | **33.61** | **11.21** | **25.76 MB / 31 frames** |

At the size target (25.8 MB per chunk, ~309 MB for the take, 17 % under
Gracia), encoding 0 with real 31-frame chunks, readable by the current viewer.
Measured on one chunk only (45-76); the take's 12 chunks are not validated yet.
The gap left to the published frames (+0.9 flicker) is position that four
terms cannot hold.

**Papers (ideas only), against what we found:**

| paper | idea | fit with VGS / our results |
|---|---|---|
| ReCon-GS | motion as summed motions of hierarchical anchors | best fit: translation-only anchors = dictionary atoms, weights = the four terms (rotating anchors make a splat's path depend on its offset, which encoding 0 cannot store); next step |
| QUEEN | L0 gate on residuals, quantization-aware training | gate fits a position residual on top of anchors; quantization not needed (DX5: appearance is not lost) |
| PackUV | freeze the static, quantize in training | freezing = `--temporal-lock-shared`; done |
| Dynamic 3D Gaussians | fixed appearance per splat | scale and SH: yes; opacity: no (OB) |
| 4DGCPro | L1 / rate penalty on per-frame changes | appearance: rejected (OB); may suit a position residual |
| CDGS | differentiable record budget | fits: fewer records would pay for more splits; untried |
| OMG4 | merge short-lived records | little to gain (~2k one-frame records of 332k) |
| TED-4DGS | learnable activation windows | births with generations already give one lifetime per record |
| FreeTimeGS / SharpTimeGS | soft temporal opacity | clashes with one hard lifetime per record |
| TRiGS | kNN rigidity | subsumed by anchors |
| MoRGS | optical-flow loss | motion correctness, not size or codec; not now |

### 5.4 Known weaknesses of these results (review of 2026-09-25)

An outside review of this record raised these; all are accepted.

1. **The population count confounds death with dimming.** Opacity > 0.1 is one
   threshold. It must be read with several thresholds, a coverage measure of the
   subject and image quality; Wj especially.
2. **Motion vs repeated re-training is not separated.** D4-D6 train a frame once.
   Needed: the same frame repeated as a sequence through the same window, budget
   and state propagation; compared with the real sequence and with one long
   continuous training of the fixed frame.
3. **Several comparisons change more than one thing** (5.2 attribution note).
4. **The Forge reference is not uniform** (two recipes, 45-50 and 51-76). The
   final comparison needs one Forge recipe over the whole range.
5. **Flicker needs a detail and motion companion.** 16 px blocks can hide lost
   detail; the per-camera affine colour map separates colour from
   reconstruction but is not the published colour. Needed: a high-frequency
   measure, temporal crops of face, hands and clothes, and a check with the
   published colour. Gracia's PSNR, bounded by registration, does not rank its
   quality against spirula.
6. **Robustness is untested.** Finalists need several seeds and a second take
   with harder motion and occlusion.
7. **Implementation risk for births.** Scale and SH are shared across frames.
   Reusing a row that is still faintly visible in an earlier frame and changing
   its shared attributes would alter that frame. Births must only take rows dead
   in *every* frame (held ones included), and a test must show earlier frames
   unchanged.

---

## 6. Reverted, with reasons

| idea | why it was tried | result | fate |
|---|---|---|---|
| 1st-order smoothing of motion | simplest temporal coupling | froze motion, −3 dB | replaced by 2nd order |
| Opacity smoothing in logit space | same operator as the rest | killed splats: a dead frame's logit (≈ −10) outweighs a live one's (+2) when averaged | now in opacity space |
| `--temporal-pin-first` | continuity across chunks | −1 dB and more flicker than retraining the frame | removed (held frames in the window replace it) |
| Freezing scale after the first chunk | Gracia freezes scale | −2 dB, flicker ×2 | removed (Gracia also has births) |
| MCMC noise forced off in chunk mode | noise moves splats independently per frame | population halved over six chunks | now left at the user's value |
| Split rebirth (long-axis split of the largest splats into rows dead in every frame, `--temporal-split-*`) | give dead rows back | halves drop below the 0.1 count; rarely met criterion; −16 % vs −10 % | code removed |
| Fresh Adam moments per entering frame (`--temporal-fresh-moments`) | Forge restarts Adam every frame | −62 %: Adam's first steps push rarely used splats off | code removed |
| Per-frame scale (`--temporal-per-frame-scale`) | Forge changes scale ×2.5/frame | no change | code removed |
| Held-out-camera evaluation | standard protocol | fog from neighbours' background splats | replaced by trained views + mask |
| Opacity change band on written frames (`--temporal-opacity-band`, OB) | per-splat opacity vibration 4x Gracia's | vibration down to Gracia's, rendered flicker up 40-50 % | code removed |
| Stronger smoothing (OC, FC6) | lower codec position error | codec error down, training quality down as much | weights stay at 1 |
| Joint refine on the codec's positions (FC4/FC5 REF, RB) | let appearance absorb the codec's position error | worse than encoding the published frames | not used |

Hypotheses disproved on the way: fp32 optimizer (D5), auxiliary warmup
schedules (Wr), number of steps (R2), interleaving frames (Wp), initial copies of
distant frames being the only cause (extrapolation did not stop it), MCMC noise
schedule (Wn).

---

## 7. What SMNForge needs to use this

**Code layout (2026-09-28):** chunk training's TrainerSession members live in
`src/app/TrainerChunk.cpp` (warps/births inputs in `src/app/TemporalInputs.cpp`,
engine side in `src/engine/EngineTemporal.*`); `TrainerCore.cpp` keeps only the
calls, so upstream merges stay small. Forge runs the spirula copy in
`build_tc_deploy` (registry `Paths/Spirula`, was `build_temporal_cuda_vs2022`).

**Done 2026-09-28 (uncommitted), SMNForge branch `TemporalChunk`:**
`--graciaseed chunk` does points 1-4 below; details and how to run it in
SMNForge's `GRACIA_CHUNK_TRAINING.md`. On this side, `--temporal-warp-dir auto`
and `--temporal-birth-dir auto` (`src/app/TemporalInputs.cpp`, C++ port of
`hull.py`/`warps.py`/`births.py`; on 45→47 it gives 10304 vs 10302 subject
points and warp RMS 24.0→16.5 vs 24.1→16.7 mm) fit warps and births inside
spirula, so Forge passes only frame folders. Prune keeps rows (removed splats
written back with opacity logit -20). First test: battery FC,
`outputs/tc/battery_FC.ps1` → `FC_report.md`, on the copy `VIDEOTIKI_CHUNK`.

The original plan, for reference. Forge ran spirula once per frame
(`graciarenderer.cpp`, `smnprocesstasks.cpp` → `MakeGaussianUsingSpirula`).

1. **Prepare frames without training them.** SfM with the locked prior, masks
   and undistort into `.work\NNN\undistorted`, as today. The option is missing:
   `GraciaRenderer` refuses `-lfs 2` ("the Gaussian trainer is set to None").
   Frames 51-76 had to be extracted by training them normally
   (`SMNForge.exe --gracia <take> --graciarange 51:76 --lfs 3 --graciakeepwork`,
   ~5.5 min/frame).
2. **One spirula run per segment**, with:
   - `--data <first frame> --temporal-frames "<dir2>;...;<dirN>"`;
   - chunk settings or the window (`--temporal-window 6 --temporal-frame-steps
     4000 [--temporal-first-frame-steps 8000]`);
   - the smoothing flags;
   - `--ppisp-from` a take-wide PPISP;
   - `--init-ply` the first frame's model.
3. **Warps.** Compute GraciaWarp between consecutive frames' sparse clouds,
   restricted to the subject, and pass the folder with `--temporal-warp-dir`.
   Forge already has `graciawarp.cpp` (branch `GraciaWarp`, `97aa162`) writing a
   warped PLY; it would have to write the graph (`NNN.bin`) instead, or port
   `warps.py`.
4. **Outputs** come as `frames\NNN\splat.ply` with the same row order. Forge's
   take-mask prune removes rows, which breaks identity; for `.vgs` it must mark
   splats dead instead of deleting them.
5. **Build:** spirula's `build_tc` (section 9). Do not overwrite the exe Forge
   is configured with.

---

## 8. Next steps (current plan, in order)

**Plan of 2026-10-04** (supersedes the list further down; best result in 5.15):

1. Anchor motion (ReCon-GS's idea): per chunk, anchors with translation
   trajectories; each splat's position = base + four anchor weights + an
   L1/L0-penalised residual. `vgsplyseq` loads that model instead of fitting it,
   so the codec's position error is the residual alone.
2. A record budget (CDGS's idea) to pay for splits within the size target.
3. The whole take through Forge (12 chunks) to validate size and quality.
4. `vgsplyseq` inside Forge's chunk path.

Done since the review: better metrics (B1), repeated-frame control (B2), births
(B3), full take (B4), flicker isolation (B5-B7), candidate on the full take
twice (B8). **Current recipe: B8** (5.12).

Before the quality runs below, address the birth/lifetime and VGS representation
gates in [TEMPORAL_VGS_TEST_PLAN.md](TEMPORAL_VGS_TEST_PLAN.md). The 2026-09-27
audit executed 17 CPU checks and scanned both B8 sequences. It reproduced unsafe
birth-state assumptions and the legacy direct-position interpolation mismatch;
VGS scale is static per chunk record whereas B8 scales still vary. These checks
do not replace GPU render/optimizer validation. The separate plan includes the
results, exact commands, prerequisites, and serial runners for the quality runs.

1. **Detail gap** (~0.8 dB below Forge): B9 tested 8000 steps and SH learning
   rate x2 on 45-64 (section 5.13). Neither met the detail promotion threshold.
   Finish B8R repetitions, inspect worst pairs, then confirm the promising 8k
   fit gain on 45-76 with repetitions before changing the reference recipe.
2. A **uniform Forge baseline** over 45-76 (the owner's recipe on every frame)
   so the reference is one pipeline; crops of face, hands and clothes.
3. **More seeds** for B8 (3 runs) to bound the flicker spread (15 % seen).
4. A **second take** with harder motion and occlusion (owner to choose it).
5. Forge integration (section 7), then `.vgs` writing from the per-frame PLYs
   after the lifetime, representation and round-trip gates in the VGS test plan.

Success targets: regional flicker ≤ 8, fit ≥ 30.5 dB held to the end of the
take, covered surface ≥ 88 % to the end. B8 meets them on VIDEOTIKI except
flicker ≤ 8 in one of two runs (8.87).

---

## 9. Reproducing

**Build** (`build_tc.cmd`, as used):

```bat
@echo off
setlocal
cd /d D:\Dependencias\spirula-studio
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8"
set "PATH=%CUDA_PATH%\bin;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%"
cmake -G Ninja -B build_tc -DCMAKE_BUILD_TYPE=Release -DSS_BACKEND=cuda -DSS_BUILD_SAM=OFF -DSS_BUILD_SFM=OFF -DSS_BUILD_GUI=OFF "-DCMAKE_CUDA_COMPILER=%CUDA_PATH%\bin\nvcc.exe" >nul || exit /b 1
cmake --build build_tc -j 14 || exit /b 1
```

- `build_develop.bat` picks the newest VS (18), which CUDA 12.8 rejects; this
  script pins VS 2022.
- `-DSS_BUILD_GUI=OFF` is needed: with SfM off the GUI still includes
  `vulkan.h`.
- A clean build takes about an hour, an incremental one a few minutes.
- Copy `build_tc\spirula.exe` to `outputs\tc\bin\` before experiments: Windows
  cannot relink an exe that is running.

**Tooling** (`reference\temporal\`, hand-run, paths hard-coded to this machine):
- `common.ps1`: dataset paths, `$Exe`, the owner's per-frame flags (`$Common`,
  `$Warm`).
- `chain3.ps1 <name> <first> <last> <chunk> <steps> [flags]`: chain of chunks
  with a context frame; writes `<name>.seq` (frame → run, index). This is C3.
- `window.ps1 <name> <first> <last> <W> <A> [flags]`: sliding window; writes
  `.seq`.
- `rchain.ps1 <name> <first> <last> <steps>`: plain per-frame chain (control).
- `evalply.ps1 <ply> <frame> <name>`: renders every 8th camera of one PLY, with
  no training, into `outputs\tc\q\<name>`.
- `evaluate.py [first:last] [--pairs] <run|name.seq>...`: full table for
  Gracia, Forge and runs. `quick.py first:last <seq>...`: fit and flicker.
  `population.py <first> <run|name.seq>...`: subject population.
- `hull.py`: visual-hull subject selection from COLMAP poses and masks.
  `flicker_lib.py`: PLY/voxel helpers.
- `register.py`, `gracia_assets.py`, `evalgracia.ps1`: Gracia registration,
  PLYs and renders. `gracia_to_colmap.json` is the registration used.
- `mintprobe\`: Qt console tool dumping `.mint` frames. Build with
  `build.cmd` after copying `mintfile.cpp/h` from the despill-candidate folder.
  Run with the Qt `bin` folder on `PATH`.
- `warps.py <first> <last> <outdir>`: deformation graphs between consecutive
  frames.
- `export_seq.py <run | name.seq> <first> <out_dir>`: copies a run's frames into
  one folder named by take frame (`0045.ply`, `0046.ply`, ...) to play them as an
  animation. **Every battery's finalist is exported this way** to
  `D:\Dependencias\spirula-studio\outputs\tc\sequences\<run>\`.
- `make_gif.py <run> <out.gif> [camera]`: loop of video | Forge | run | Gracia
  from one fixed camera.

Example (the C3 result, then its evaluation):

```powershell
& D:\Dependencias\spirula-studio\reference\temporal\chain3.ps1 C3 45 76 6 8000 `
  --temporal-smooth-every 50 --temporal-smooth-position 1 --temporal-smooth-rotation 1 `
  --temporal-smooth-opacity 1 --temporal-smooth-color 1
python D:\Dependencias\spirula-studio\reference\temporal\evaluate.py 45:76 --pairs C3.seq
```

**Traps met:**
- The agent's bash heredocs lose backslashes: write scripts to files.
- PowerShell variables are case-insensitive (`$s` overwrote `$S`).
- `SMNForge.exe` is a GUI app: no console output, and it returns immediately.
  Watch its process or `.work` instead.
- Comment blocks over 3 lines fail the build.
- The eval loader samples with replacement.
- Per-frame depth/normal files exist only for frame 45 of this take.

## 10. Follow-up execution (2026-09-27)

The B8R battery finished three full 45-76 repetitions. Mean fit was
30.840/30.842/30.879 dB; final fit 30.563/30.523/30.634; detail
35.897/35.911/35.905; flicker 7.778/7.695/7.304; final coverage
90.41/90.95/90.30%. Source:
`outputs/tc/B8R_20260927_battery/status.json` and per-run metrics.
These runs support B8's stability on this take, while historical B8b's 8.87
flicker cautions against treating 7.78 as a hard upper bound.

B10 now runs three full-length 8000-step repetitions serially, using the same
original executable as B8/B9. Read
`outputs/tc/B10_20260927_battery/status.json`; compare full-span detail,
fit, coverage, flicker and worst pairs before changing the B8 reference.
The visual check of B9's worst-pair frames from a fixed camera is saved at
`outputs/tc/audit_20260927_02/B9_worst_pairs_H2_P10.png`.

Birth handling has since changed in Spirula source, separate from B10:
births obey mutual spacing, row reuse stays below the 1/255 raster cutoff in
all resident frames, old frame attributes are preserved, reused-row moments
are reset, generation events are recorded, and smoothing respects generations.
The focused CPU shim reports 16/16 temporal contracts passing in
`outputs/tc/audit_20260927_warp_valid_v3/summary.json`. It also found and
excludes 10 near-zero quaternion warp nodes out of 124,821 in this take.
CUDA compiled;
Vulkan linking is blocked by unresolved `__std_*` symbols in the existing
toolchain, so backend parity is unverified. B11 is queued after B10 for one
full CUDA trial with the new executable. Its queue status is
`outputs/tc/B11_20260927_queue_status.json`. See
[TEMPORAL_VGS_TEST_PLAN.md](TEMPORAL_VGS_TEST_PLAN.md), section 8, for the
exact artifacts, limitations and next gates. This paragraph records the earlier
queue state; the completion and export follow-up below supersedes it.

## 11. Completed training and VGS comparison (2026-09-27)

B10 completed all three full 45-76 repetitions: fit mean
31.230/31.217/31.214, final 31.022/30.992/31.047, detail
36.084/36.087/36.099, flicker 7.041/7.198/7.922. Its mean detail gain
over B8R is about 0.186 dB, below the previously declared 0.2 dB criterion.
The fit improvement is repeatable on this take; it does not prove the cost of
8000 steps is justified or validate a second take.

B11 (corrected births, B8 training budget) completed: fit mean 30.778,
final 30.490, detail 35.894, flicker 7.299, final coverage 89.895%.
It passes the predeclared reference gate. Only one B11 run exists; the three
B8R runs are supporting historical evidence, not repetitions of this binary.

The real CUDA birth fixture now passes 8/8 cases, including both sides of the
1/255 threshold, held-frame render invariance, 100 optimizer steps and smoothing
on/off. The fixture's initial missing camera distortion row was corrected;
that failure was test setup, not evidence against the training algorithm.
Log: `outputs/tc/birth_gpu_validation.log`. Vulkan remains unverified.

C12 freezes all 32 B11 PLYs byte-for-byte, preserves birth generations, schema,
explicit ticks and hashes, and compares four outputs without retraining:
lossless samples, existing VGS encoding 0 held frames, adaptive tracks and
int16 residuals. Sizes refer to real compressed `.vgs`, never PGS proxies.
Experimental modes require an opt-in decoder and are not yet compatible with
existing VGS viewers. `.mint` and the default decoder remain unchanged.

The synthetic fixture passes native round trips and Chrome/WebGL2 upload and
GPU/CPU parity on RTX 4070. Existing encoding 0 uses actual viewer packing;
native pages upload directly from decoded WASM views. Full-scene web rendering
and sorting are outside this benchmark. Existing VGS regression tests: 11/11.
For pending full-sequence results and low-token commands see
[TEMPORAL_VGS_TEST_PLAN.md](TEMPORAL_VGS_TEST_PLAN.md), section 9.
