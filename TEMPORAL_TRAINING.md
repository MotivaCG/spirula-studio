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
  Seed noise was never measured, so treat differences under ~20 % as unproven.

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
| `.vgs` container | `D:\Trabajos\THE4DSCANNER\VGSFileFormat` (`FORMAT.md`, `core/src/vgsframe.cpp` is the normative decoder) |
| SMNForge | `D:\Trabajos\ScanMeNow\RaspberrySoft\SMNForge` (branch `GraciaWarp`, commit `97aa162`, has `graciawarp.cpp`; the Profile build `build\Desktop_Qt_6_8_0_MSVC2022_64bit-Profile\release\SMNForge.exe` was used to extract frames 51-76) |
| earlier temporal attempt | spirula branch `DualGSAstra` (`docs/notes/dualgs.md`): a DualGS-style deformation graph; the owner reports it was "a complete disaster" |
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

Side findings about the owner's `.vgs` encoder: `VGSFileFormat/core/src/vgsencode.cpp:468`
rejects any `.mint` that is not 30 Hz ("source timebase is not 30 Hz"). The
header supports any timebase, but the encoder never derives it. Both non-tiki
samples are 25 and 50 Hz. It was not fixed.

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
- **Freezing scale rejected** (−2 dB, flicker ×2). Gracia can freeze it only
  because it also has births.
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

**Conclusion.** The death is **not caused by chunk or window training**. Every
warm start without births loses subject splats as people move, **including the
owner's own pipeline**: for the optimizer, switching off a splat whose surface
moved is cheaper than moving it.
- Smoothing (logit-space opacity especially) and missing warps accelerate it.
- Warps and an opacity boost on entry slow it.
- Births are what keep a population: Gracia's per-chunk refresh, or the newer
  Forge recipe's `--init-ply-add-points 1` plus densification (~175k stable).

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

Hypotheses disproved on the way: fp32 optimizer (D5), auxiliary warmup
schedules (Wr), number of steps (R2), interleaving frames (Wp), initial copies of
distant frames being the only cause (extrapolation did not stop it), MCMC noise
schedule (Wn).

---

## 7. What SMNForge needs to use this

Forge today runs spirula once per frame (`graciarenderer.cpp`,
`smnprocesstasks.cpp` → `MakeGaussianUsingSpirula`).

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

## 8. Next steps (proposed, agreed direction)

1. **Births that keep identity.** When a frame enters the window, seed the
   subject points of its sparse cloud that fall in gaps (far from live splats)
   into rows that are dead in the frames still training and faint in held ones:
   colour of the point, scale from point spacing, low opacity, zero moments.
   Cap about 2 % per frame. In earlier frames those rows stay dead, so there is
   no pop. This is Gracia's lifetime mechanism, and Forge's `add-points`
   without breaking identity.
2. Measure on 50-60 with **all three metrics**: A = warp + births, B = A +
   entry boost ×2, against Wj, Ws, Forge and Gracia.
3. Best of A/B on the full 45-76 window, with a table and a GIF
   (`make_gif.py`).
4. Seed replicates.
5. Forge integration (section 7), then `.vgs` writing from the per-frame PLYs
   (fix the 30 Hz check in `vgsencode.cpp:468` first).

Success targets: regional flicker ≤ 8, fit ≥ 30.5 dB held to the end of the
take, subject population stable within ±10 %.

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
