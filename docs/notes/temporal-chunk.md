# Temporal training of takes: chunks and sliding window

Report for whoever continues this work (human or LLM). Branch `TemporalChunk` of
spirula-studio, forked from `Gracia`. Written 2026-09-25. Conversation language
with the owner is Spanish; code, comments and commits are English.

Everything below was measured on one take (VIDEOTIKI, frames 45-76) with single
runs. Seed noise was never measured: treat differences under ~20 % as unproven.

---

## 1. Goal and why

The owner captures people with a 105-camera inward-facing rig (THE4DSCANNER /
ScanMeNow) and trains one 3DGS model per frame with spirula, driven by SMNForge.
Played in sequence, those models flicker. Gracia (a commercial 4DGS service)
produces sequences that are visibly stable. Goal: train takes in spirula as
stable as Gracia, without losing quality, ideally producing per-frame splats with
a persistent identity so they can later be written as `.vgs` (the owner's own
4D container, `D:\Trabajos\THE4DSCANNER\VGSFileFormat`).

### What Gracia's files say (measured, not guessed)

From `tiki.mint` (the same take processed by Gracia) and two other samples, with
the owner's reverse-engineered decoder (`GraciaConverter/.../mintfile.cpp`,
format spec `MINT_FORMAT.md` next to it):

- Time is cut into chunks of 32 intervals (~1 s). Inside a chunk one splat
  population persists: position/rotation/opacity/base colour vary per sample,
  **scale is fixed**. Splats have hard lifetimes (born / die per interval).
- Chunk k+1 continues chunk k: 88-94 % of visible splats have an exact twin
  (<0.1 mm, same scale) across a boundary; their scale stays identical over
  4 chunks (no drift). So persistence comes from training, not compression.
- Every ~192 frames (6 chunks) there is a full reset (0 % twins, new splat set):
  independent segments, probably trained in parallel.
- Per splat, colour and opacity jitter almost like noise (roughness ~1), but the
  jitter is uncorrelated between splats, so region-level change is small. What
  reads as flicker is **coherent regional change**, which Gracia does not have.
- Each chunk refreshes ~10 % of its splats (births/deaths); the population of the
  subject stays ~165-185k.

---

## 2. Bench and measurement protocol

- Data: `C:\Users\Victor\Documents\Gracia4DGSConverter\VIDEOTIKI\output\.work\000000NN\undistorted`
  (images, masks, `sparse/` with a per-frame SfM cloud). Frames 45-76. Camera poses
  are bit-identical across frames (locked prior), which chunk training requires.
- Baseline "Forge": the per-frame models Forge wrote in `.work/NN/.../smn/step-*.ckpt`.
  **Caveat found late:** frames 45-50 come from the owner's recipe (warped init,
  PPISP frozen, no densify, `--refine-start-iter 99999999`); frames 51-76 were
  produced by a newer Forge build run for this work, with another recipe
  (`--init-ply-add-points 1`, densification on, `--opacity-boost 1.5`, PPISP per
  frame). Regional flicker is similar for both (20.9 vs 22.4) but population is not.
- Gracia: `tiki.mint`, time t = frame/30 s, registered to our COLMAP frame by scaled
  ICP (`gracia_to_colmap.json`, scale 1.874, residual at sampling-noise level); our
  cameras are moved into Gracia's frame so its SH need no rotation, and it is
  rendered with our renderer.

Metrics (tooling in `reference/temporal/`, see section 7):

| metric | what | better |
|---|---|---|
| **Regional render flicker** (main) | per fixed camera, 16 px block means inside the mask of \|Δrender − Δvideo\| between consecutive frames, after one colour map per camera. Real motion cancels. ×1e-3 | lower |
| Fit | masked, per-channel affine colour-corrected PSNR on every 8th camera (trained views) | higher |
| Subject population | splats with opacity > 0.1 whose centre is inside the visual hull (mask in ≥ 90 % of the cameras that see it) | stable |
| Per-splat stats | median frame-to-frame change of position/colour/opacity/scale of the same row (only when identity holds) | — |

Rejected metric attempts (and why): held-out cameras (neighbours' background
splats sit in front of them: fog, PSNR ~8); whole-image PSNR (room background
dominates); voxel luminance change (has a floor that depends on splat count and
texture, not flicker). Pixel-level flicker is dominated by sensor noise; the
regional one is what the owner perceives ("small luminosity changes").

---

## 3. What is in the code now (kept)

`src/engine/EngineTemporal.{h,cpp}` + hooks in `src/app/TrainerCore.{h,cpp}`,
rows in `src/config/TrainConfig.h`, help in `src/i18n/catalog/TrainFields.h`.

- **Chunk training** `--temporal-frames "dir1;dir2;..."` (frames after `--data`).
  One population; per frame: means, quats, opacities, features_dc and their Adam
  moments (+ per-splat bias steps) held in a device slot per frame and swapped into
  the live buffers before each step with `memcpy_async` (both backends, no new
  kernel), together with that frame's `DataManager` (`engine().dm`). Shared: scale
  and higher-order SH. Forced: `quantization_level 0`, no densification,
  `export_keep_all_splats`. One PLY per frame in `frames/NNN/`, same row order.
  `eval()` scores each frame against its own images; `--save-eval-images` writes
  renders plus `eval_views.txt` next to each frame's metrics.
- **Temporal smoothing** every `--temporal-smooth-every` steps, on the host:
  gradient step on the 2nd time difference for position/rotation (constant velocity
  is free), 1st difference for opacity (in opacity space, not logit) and colour.
  Weights `--temporal-smooth-{position,rotation,opacity,color}` in [0, 1].
- **Sliding window** `--temporal-window W` + `--temporal-frame-steps A` (+
  `--temporal-first-frame-steps`, `--temporal-history`): frames enter one every A
  steps, the oldest trainable is written and **held** when the window is full (held
  frames are not trained but neighbours are smoothed towards them), so there are no
  chunk boundaries. Each frame runs its own learning-rate and MCMC-noise schedule by
  its own age. A frame enters as the previous one moved by a **warp**
  (`--temporal-warp-dir`) or, without one, by constant-velocity extrapolation;
  `--temporal-entry-opacity-boost` multiplies its opacities on entry.
- **Warp** input: `NNN.bin` per frame (deformation graph from frame NNN-1 to NNN,
  computed by `reference/temporal/warps.py`, a numpy port of Forge's `GraciaWarp`
  restricted to the subject); spirula skins every splat to its 4 nearest nodes.

---

## 4. Experiment log

### 4.1 Chunks of 6 frames, 45-50 (8000 steps per frame, init = Forge frame 45)

| run | change | regional flicker | fit dB | per-splat opacity change |
|---|---|---|---|---|
| Gracia | — | 9.1 | (23.2, registration-bound) | 0.007 |
| Forge (owner's recipe) | — | 20.9 | 31.07 | identity broken (scale ×2.5/frame) |
| T1 | chunk, no smoothing | 9.6 | 30.94 | 0.10 |
| T2 | 1st-order smoothing everywhere | 10.6 | **27.13** | motion frozen |
| **T3** | 2nd-order motion smoothing w=1 | **8.4** | 30.39 | 0.005 |
| T4 | T3, 12k steps/frame | 10.3 | 30.57 | — |
| T5 | T3, weights 0.5 | 10.7 | 30.55 | — |

Learned: joint training alone already halves flicker vs Forge; 1st-order motion
smoothing kills motion (Laplacian flattens trajectories); 2nd order keeps it.

### 4.2 Chains of chunks over 45-76 (six chunks)

| run | recipe | regional flicker | fit dB (start → end) |
|---|---|---|---|
| C1 | chunks share a **pinned** boundary frame | 16.4, spikes 20-56 at boundaries | 30.6 → 26.6 |
| C2 | + context frame, **frozen scale**, MCMC noise on | 13.1 | 30.3 → 26.0 |
| **C3** | context frame, not pinned, scale trained, noise on | **7.9** (Gracia 9.5, Forge 22.4) | 30.3 → **27.2** |

Second chunk alone (50-55, from C2's frame 50): pinned+frozen 13.1 / 27.8-28.6 dB;
pinned 8.8 / 29.1-29.4; **free 6.8 / 29.6-30.2**.

Learned: a chunk's end frames are ~6× less constrained by the 2nd difference and
flicker; a **context frame** trained past the end and dropped fixes it. Freezing
scale across chunks costs ~2 dB (Gracia can freeze because it also has births).
Pinning the boundary costs ~1 dB. C3 is the best stability result so far, but the
fit decays through the take.

### 4.3 Why quality decays: splats of the subject die

Subject population: C3 134k → 49k over 32 frames; background ~55k constant. The
losses are on the subject.

Diagnosis on frames 50-56 (4000 steps/frame, same start of 133.7k):

| run | change | frame 50 | frame 56 |
|---|---|---|---|
| D4 | single frame, plain path | 145.8k | — |
| D3 | chunk, no smoothing | 141.8k | 115.6k |
| D2 | no motion smoothing | 125.6k | 120.8k |
| D0 | all smoothing (C3 recipe) | 110.8k | 108.8k |
| D1 | no opacity smoothing | 126.0k | 104.4k |
| D5 | single frame, `quantization_level 0` | 146.4k | — |

Sliding windows on 50-60 (W=6 unless noted, 4000 steps, init Forge frame 50):

| run | change | 50 | 60 | 50→60 |
|---|---|---|---|---|
| Wa / Wb | motion smoothing 0.25 / 0 (+opacity, colour 1) | 109k / 114k | 92k / 94k | −16 / −18 % |
| Wd | no smoothing | 125k | 82k | −34 % |
| We | colour smoothing only | 125k | 78k | −37 % |
| Wf | fresh Adam moments on entry | 125k | **48k** | −62 % |
| Wg | entry opacity boost ×1.5 | 125k | 113k | −10 % |
| Wh | Wg + split rebirth | 125k | 105k | −16 % |
| **Wj** | entry opacity boost ×2 | 127k | 121k (139k at 54) | **−4 %** |
| Wk / Wl | per-frame scale / + boost 1.5 | 127k / 127k | 81k / 112k | −37 / −12 % |
| Wn / Wo | noise on the frame's own schedule / + boost 1.5 | 124k / 125k | 81k / 114k | −35 / −9 % |
| Wp / Wq | window of 1 / + fresh moments | 129k / 127k | 65k / 41k | −49 / −68 % |
| Wr | window of 1, auxiliary schedules scaled | 128k | 65k | −49 % |
| Ws | window 6 + **warp** | 124k | 100k | −20 % |
| Wu | window 1 + warp | 128k | 91k | −29 % |

Plain per-frame chains with **no temporal code at all** (spirula's normal path,
init = previous frame's PLY): R1 (4000 steps) 128k → 72k (−43 %); R2 (12166 steps,
Forge's count) 125k → 89k in 4 frames. And the owner's own Forge chain for 46-50:
192k → 175k → 162k → 142k → 132k. Its `warped_init.ply` carries exactly what the
previous frame had (no births).

**Conclusion:** the death is not caused by chunk training. Any warm start without
births loses subject splats as people move (a splat whose surface moved is cheaper
to turn off than to move). Smoothing (opacity in logit space especially) and
missing warps accelerate it; the entry opacity boost and the warp slow it; births
(Gracia's chunk refresh, the newer Forge recipe's `--init-ply-add-points` +
densification) are what keep the population. Stability results (C3) stand; the
quality decay is the open problem.

---

## 5. Tried and reverted (and why)

| idea | result | why removed |
|---|---|---|
| 1st-order smoothing of motion | froze motion, −3 dB | replaced by 2nd order |
| Opacity smoothing in logit space | killed splats: a dead frame's logit (−10) outweighs a live one (+2) | now smoothed in opacity space |
| `--temporal-pin-first` (hold the chunk's first frame) | −1 dB, more flicker than training it | removed; windows hold written frames instead |
| Freezing scale after the first chunk | −2 dB, flicker ×2 | removed (just not passing `--scales-lr 0`) |
| MCMC noise forced off in chunk mode | population halved over 6 chunks | noise left at the user's value |
| Split rebirth (long-axis split of large splats into rows dead in every frame) | did not raise the subject population (halves drop below the 0.1 count; criterion rarely met) | code removed |
| Fresh Adam moments for each entering frame | −62 % population: Adam's first steps push rarely used splats off | code removed |
| Per-frame scale | no change vs shared scale | code removed |
| MCMC noise on the global schedule (window) | a real bug (late frames got ~65× less noise) but fixing it changed nothing measurable | fix kept |

Hypotheses disproved on the way: fp32 optimizer (D5), auxiliary warmup schedules
(Wr), number of steps (R2), interleaving several frames (Wp), initial copies of a
distant frame being the only cause (window extrapolation did not stop it).

---

## 6. What SMNForge would need

Forge (`D:\Trabajos\ScanMeNow\RaspberrySoft\SMNForge`, `graciarenderer.cpp`)
today runs spirula once per frame. To use this:

1. **Keep the per-frame preparation as is** (SfM with the locked prior, masks,
   undistort, into `.work/NNN/undistorted`) but do not train per frame; a
   "prepare only" mode is missing: `GraciaRenderer` refuses `-lfs 2` (trainer None).
2. **One spirula run per segment**: `--data <first frame dir> --temporal-frames
   "<dir2>;<dir3>;..."` and either chunk settings (`--steps-scaler` =
   frames × steps / 30000) or the window (`--temporal-window 6
   --temporal-frame-steps N [--temporal-first-frame-steps M]`), smoothing flags,
   `--ppisp-from` a take-wide PPISP, and the first frame's model as `--init-ply`.
3. **Warps**: run the GraciaWarp computation between consecutive frames' sparse
   clouds (restricted to the subject via the masks) and pass the folder with
   `--temporal-warp-dir`; or move `reference/temporal/warps.py`'s logic into Forge
   (it already has `graciawarp.cpp` on branch `GraciaWarp`, commit 97aa162).
4. **Outputs**: frames come out as `frames/NNN/splat.ply` (+ `frames.txt`), all
   with the same row order; the take-mask prune Forge applies must keep row order
   (or be replaced by marking splats dead) if `.vgs` writing is to follow.
5. Build: spirula's `build_tc` tree (VS2022 + CUDA 12.8, `-DSS_BUILD_GUI=OFF`).
   Forge's registry points at `build_temporal_cuda_vs2022/spirula.exe`, untouched.

---

## 7. How it was tested (reproduce)

Tooling in `reference/temporal/` (hand-run, not part of any build; paths are the
owner's machine and must be edited). Experiments wrote to `outputs/tc/`
(git-ignored) and ran a **copy** of the exe (`outputs/tc/bin/spirula.exe`) so
`build_tc` could be rebuilt while a run was going. One GPU job at a time.

- `common.ps1`: Forge's per-frame flags (`$Common`, `$Warm`), dataset paths, `$Exe`.
- `chain3.ps1 <name> <first> <last> <chunk> <steps>`: chain of chunks with a
  context frame; writes `<name>.seq` (frame → run, index).
- `window.ps1 <name> <first> <last> <W> <A> [flags]`: sliding window; writes `.seq`.
- `rchain.ps1`: plain per-frame chain through the normal path (control).
- `evalply.ps1`: renders every 8th camera of one PLY with no training
  (`--num-iterations 0 --eval-mode interval --save-eval-images 1`).
- `evalgracia.ps1`, `gracia_assets.py`, `register.py`: Gracia frames as PLYs,
  cameras moved into Gracia's frame, registration.
- `mintprobe/`: dumps `.mint` frames (build against `mintfile.cpp/h` from
  `THE4DSCANNER/GraciaConverter/Gracia4DGSConverter/build/despill-candidate`, Qt 6.8).
- `evaluate.py [first:last] [--pairs] <run|x.seq>...`: full table (voxel stats,
  fit, render flicker, per-pair flicker) for Gracia, Forge and runs.
  `quick.py first:last <seq>...`: fit + flicker only. `population.py first <run>...`.
  `hull.py`: visual-hull subject selection. `flicker_lib.py`: shared helpers.
  `make_gif.py <run> <out.gif>`: side-by-side loop video | Forge | run | Gracia.
- `warps.py first last outdir`: deformation graphs between consecutive clouds.

Traps met: the eval loader samples cameras with replacement (a camera may be
missing or repeated; match views by content, as the scripts do); heredocs in the
agent's bash lose backslashes (write scripts to files); PowerShell variables are
case-insensitive (`$s` overwrote `$S`); `SMNForge.exe` is a GUI app (no console
output, returns immediately); linking fails while an experiment holds the exe;
spirula's comment-length check fails the build on blocks over 3 lines.

---

## 8. Next steps

1. **Births that keep identity**: when a frame enters the window, seed the subject
   points of its sparse cloud that fall in gaps (far from live splats) into rows
   dead in the trainable frames and faint in held ones (colour of the point, scale
   from point spacing, low opacity, zero moments). Cap ~2 % per frame. Measure A =
   warp + births, B = A + entry boost ×2, on 50-60 with all three metrics.
2. Best of A/B as a full 45-76 window; table vs Gracia, Forge, C3; GIF.
3. Replicates for seed noise.
4. Forge integration (section 6), then `.vgs` writing from the per-frame PLYs
   (VGS encoder currently only imports 30 Hz `.mint`: `core/src/vgsencode.cpp:468`).
