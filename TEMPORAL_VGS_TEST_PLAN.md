# Temporal training -> VGS: audit, test plan and execution handover

Updated 2026-09-27 (Europe/Madrid). Current execution status is in section 8.
Historical training results remain in [TEMPORAL_TRAINING.md](TEMPORAL_TRAINING.md).
Read this file and the latest small `status.json`/`summary.json` first; do not reread
the entire historical report or dump training logs on every turn.

## 1. Current decision and scope

**B8 is a promising training recipe, not yet a validated PLY-to-VGS pipeline.**
Keep its artifacts. First settle lifetimes and the VGS representation, then spend
GPU time on detail/replicates. Do not rerun T/C/D/W/B1-B8 to rediscover their results.

- Spirula HEAD inspected: `0101f89b`, branch `TemporalChunk`; initially clean.
- VGS HEAD inspected: `bbe23dd`; existing user changes in plugins/USD were present.
  No files in that repository were changed by this audit.
- At the initial audit, no training was active. Later batteries are recorded in section 8.
- B8: W6, 4000 steps/frame, first 8000, warp + sparse-point births,
  scale LR 0.002 -> 0.0005, boost 1, smoothing off, frozen take-wide PPISP.
- B8a/B8b (45-76): mean fit 30.86/30.81 dB, final 30.5/30.6,
  detail 35.90/35.91, flicker 7.73/8.87, final sparse coverage 91%/91%.
  Forge: mean fit 30.99, final 31.0, detail 36.68, flicker 22.39.
  Gracia flicker 9.49; its registered PSNR is not a quality ranking.
- The mean fit gap is <0.2 dB; the **final** gap is 0.4-0.5 dB, not <0.2.
- The old 30 Hz-only warning is stale: current `vgsencode.cpp::setTimebase`
  derives a rational timebase. Test the built exporter; do not reimplement this fix.
- The public VGS encoder currently imports MINT. A PLY-sequence input path and
  generation/lifetime metadata still need implementation. No command in this plan
  pretends that converter already exists.

Paths used on this machine:

| Item | Path |
|---|---|
| Spirula | `D:\Dependencias\spirula-studio` |
| VGS | `D:\Trabajos\THE4DSCANNER\VGSFileFormat` |
| Existing training/evaluation artifacts | `outputs/tc` under Spirula |
| Current training executable | `outputs/tc/bin/spirula.exe` |
| Build allowed for temporal work | `build_tc` |
| Never rebuild/replace | `build_temporal_cuda_vs2022` (Forge uses it) |
| New small test tools | `reference/temporal/audit/` |

Trainer birth handling was subsequently changed in Spirula; see section 8.
The native sequence writer and compatibility tests belong to VGSFileFormat.
SMNForge integration is a subsequent phase after conversion passes; no
LichtFeld changes are needed. VGS production code remains untouched.

**Size target (owner, 2026-09-28):** a take's `.vgs` must be at least as small
as VGS compressed from Gracia's `.mint` of it, which is 31 % smaller than the
`.mint` (`tiki.mint` 448 MB -> ~309 MB, ~25.8 MB per ~31-frame chunk: tiki is 372 frames in 12 chunks; default `vgsencode` gives 371 MB, -17 %), in encoding 0
with real multi-frame chunks. One-frame chunks are not compression. Battery V1
(Forge chunk output, 2026-09-28) is far from it; see SMNForge
`GRACIA_CHUNK_TRAINING.md`.

## 2. Tests actually executed

Command (from the Spirula root):

```powershell
cmd /d /c reference\temporal\audit\run_audit.cmd --vgs-repo D:\Trabajos\THE4DSCANNER\VGSFileFormat --out outputs\tc\audit_20260927_02
```

Results: `outputs/tc/audit_20260927_02/summary.md`, `summary.json`,
`manifest.json`, the two `*_results.jsonl`, and `B8a_artifacts.json` /
`B8b_artifacts.json`. The manifest records source/library hashes and Git states.
The first attempt, `_01`, failed to compile because the shell had `cl` on PATH
without the standard include environment; the `.cmd` wrapper resolves that.

**17 checks completed: 9 PASS, 8 failed proposed contracts. These are not eight
independent product bugs.** H09 documents an invalid identity assumption, and
V01/V02 expose an intentional legacy semantic unsuitable for a naive new writer.

| ID | Requirement / experiment | Observed | Result / meaning |
|---|---|---|---|
| H01 | Held-frame parameters unchanged by birth | Old row x changes -1 -> 0 | FAIL advertised invariance; not itself proof of visible damage if truly absent |
| H02 | Reusable row invisible in an old frame | Alpha 0.0045 > raster cutoff 1/255 | FAIL: `<0.005` does not guarantee invisibility |
| H03 | Entering frame has zero new-row moments | 0 | PASS |
| H04 | Rewritten older trainable row has no stale moments | 0.25 retained | FAIL defensive contract; impact needs an optimizer/render test |
| H05 | New candidates respect the same 1 cm gap | Two births 1 mm apart accepted | FAIL: accepted births do not enter the spatial grid |
| H06 | Visible held row cannot be reused | 0 births | PASS |
| H07 | No visibility before birth after opacity smoothing | Alpha 0.001 -> 0.02575 | FAIL; B8 has smoothing OFF, so this does not explain B8 results |
| H08 | Visible retained-history row prevents reuse | 0 births | PASS |
| H09 | Row number is a permanent global identity | Same row reusable after dropping old history | FAIL assumption; reuse is legitimate only with generation/lifetime semantics |
| H10 | Single-node translation warp | Exact expected translation | PASS; not a full warp validation |
| V01 | Direct position samples, 4 intervals, t=0.375, trajectory x=[0,1,2,3,4] | x=1.375001, expected 1.5 | FAIL naive linear trajectory |
| V02 | Same fixture at sample knot t=0.25 | x=1.250001, expected 1 | FAIL even at a source sample |
| V03 | Direct position samples, one interval | x=0.5 at midpoint | PASS |
| V04 | Lifetime [begin,end) interval boundaries | Inactive/active/active/inactive | PASS |
| V05 | Positions-only and full decoder agree | Same position | PASS (agreement does not make V01 correct) |
| V06 | Scale fixed per record in a chunk | Same scale at both times | PASS format behavior; a constraint for B8 export |
| V07 | Decoder rejects normalized time 1 | Rejected | PASS API contract; writer/player needs explicit last-frame policy |

Test scope: `temporal_probe.cpp` includes the **actual** `EngineTemporal.cpp`.
Only storage, transfers and the minimal engine state use CPU shims. No optimizer,
rasterizer, GPU synchronization or backend parity is tested. `vgs_probe.cpp`
builds the **current** `vgsframe.cpp` and links supporting codec functions from
the existing `build_tests/decoder/Release/vgsdecoder.lib`; its hash is recorded.
It constructs real `DecodedChunk` inputs; it is not an encode/sign/decode round trip.

The artifact scan read all 64 PLYs without rendering/training:

| Run | Frames | Rows per frame | Finite, nonzero quaternions | Pairs with changing scale | Median pairwise p50 max-axis abs delta log scale |
|---|---:|---:|---|---:|---:|
| B8a | 32 | 395011 | PASS | 31/31 | 0.064642 |
| B8b | 32 | 395011 | PASS | 31/31 | 0.064240 |

Scale statistics use rows with alpha >0.1 in both frames, including background.
They indicate roughly 6-7% multiplicative change, not a subject-only render error.
19,402/19,659 low-to-live transitions were detected. These are **not confirmed
birth events**: exports do not contain generation IDs. Up to 19,076/19,344 rows
per frame lie between raster cutoff and the reuse cutoff; that is exposure to
the problematic range, not proof all were reused or visibly affected.

Additional initial checks performed: Python syntax, imports/CLI help, PowerShell
parser, runner plan-only mode, and input preflight for 45-64 and 45-76.
Later GPU executions and code changes are recorded in sections 7-8.

## 3. Required semantics before designing the exporter

1. **Logical identity = (source row, generation)**, not source row alone.
   Record births/reuse in a sidecar (`frame`, `row`, `generation`, `birth frame`,
   death/visibility interval and coordinate/timebase metadata). VGS indices need
   only be stable within a chunk; a cross-chunk map is an authoring aid, not a
   new decoder requirement. Do not infer exact generations from alpha thresholds.
2. Separate **absence** from low opacity. An unborn row must not render, receive
   gradients, receive smoothing from another generation or contribute stale Adam
   moments. Choose and document a hard mask/lifetime gate, or a proven equivalent.
   Merely lowering 0.005 does not guarantee absence after later optimization.
3. Freeze held snapshots semantically. Disk PLYs already written are not rewritten;
   in-memory held/older trainable frames are currently modified by births.
   Tests must distinguish those two claims. Require render invariance, and exact
   state invariance for active records; unused latent fields may differ if absence
   is enforced. H01/H04 may be replaced by stronger mask-aware checks after a fix.
4. VGS encoding 0 has **constant scale per record per chunk**, and direct-position
   interpolation uses normalized chunk time instead of within-interval alpha.
   Do not silently change this decoder behavior: that would alter existing MINT
   imports. A new native encoding must be explicitly identified/versioned, or the
   writer must use a representation already decoded with the desired semantics.
5. Start with a correctness baseline: **one interval per displayed input frame**,
   with a documented hold or interpolation policy and a duplicated terminal sample
   if needed. One-interval direct positions avoid V01/V02. This can be large and
   cause frequent chunk transitions; measure size and playback before choosing it.
   Compact alternatives: split records into lifetimes when scale changes too much,
   shorter chunks, existing position-trajectory basis, or a new native encoding.
   Static scale approximation is allowed only after the render loss is measured.
6. Declare time: 32 input frames at 30 Hz have 31 gaps. Decide whether presentation
   lasts 32/30 s with a held terminal frame or 31/30 s as a sampled trajectory.
   Never silently manufacture/drop an interval. Test local time vs source offset 45.
7. Declare quaternion ordering (Spirula wxyz -> VGS decoded xyzw), activated
   scale/opacity (PLY log-scale/logit), SH layout/degree, color space, coordinate
   handedness and any similarity transform. Rotating coordinates also affects SH.

## 4. Ordered validation gates

`READY` means a command exists here. `SPECIFIED` means a fixture/hook/exporter
must first be implemented; do not invent a passing result. Train at most one
GPU process at a time. Correctness failures block export claims, not CPU analysis.

### G0 — Repeatable audit (READY, already executed)

Run the CPU command in section 2 with a **new output name**. It refuses overwrite.
Read only `summary.json` after completion. Exit 0 means the audit completed;
`status=FINDINGS` means contracts failed. Build/runtime errors exit nonzero.
To test code changes without rescanning unchanged PLYs, append `--runs` with no
names. Reuse the prior artifact hashes/results only when the files are unchanged.

### G1 — Birth safety and identity (SPECIFIED; CPU contracts ready)

| Test | Fixture/action | Acceptance |
|---|---|---|
| G1.1 State and render invariance | Snapshot held + older trainable frame, including scales/SH/moments; birth into alpha 0, 0.001, 1/255 +/- epsilon, 0.0045, 0.005; render before/after from fixed cameras | Active records unchanged; absent records never contribute; held output byte hash unchanged; raw image max error <=1e-6 for deterministic float render |
| G1.2 Reactivation | Same scene, 100 optimizer steps on older frames after birth; test smoothing off/on separately | Zero prebirth visible pixels/contribution and no new-generation state learned in old frames |
| G1.3 Spatial allocation | Duplicate/near candidates, points across voxel boundaries, two holes, reversed candidate order, budget 1/2%, no free rows | Min accepted-center separation >= gap; no overflow; cap respected; report order bias/coverage, not exact IDs when several valid choices exist |
| G1.4 Lifetimes | Visible row -> death -> history dropped -> reuse at a distant surface; revive old generation while still resident | Generation increments exactly once per reuse; no interpolation bridge; new birth must not overwrite a still-live generation |
| G1.5 Exhaustion and constraints | Empty cloud, all rows live, zero budget; invalid negative/NaN radius, truncated warp/birth file | Empty/full cases are safe no-ops; malformed inputs fail explicitly rather than silently train a different recipe |
| G1.6 Warp | Identity, translation, known rotation, q/-q, no neighbors, blend of nodes; compare transformed means/quaternions and optimizer history | Analytic transform tolerance <=1e-5 relative scene scale; finite state; quantify whether carrying unrotated moments harms tracking |
| G1.7 Backends | The same tiny scene through the real CUDA and Vulkan engine paths | Identical lifetimes/generation events; attribute/render tolerances recorded; CPU shims do not satisfy this gate |

The birth grid, generation events and generation-aware smoothing were implemented
in Spirula, and the focused CPU cases passed. The below-cutoff reuse condition is
not a permanent hard mask. G1.1 render invariance, G1.2 optimizer reactivation,
G1.6 full warp and G1.7 backend parity remain open. B11 is a real-CUDA quality
trial, not a substitute for these contract tests.

### G2 — Representation cost on existing B8 (SPECIFIED; no training)

The parameter-only first pass is READY and was executed on 2026-09-27 for B8a/B8b.
Outputs: `outputs/tc/audit_20260927_02/B8a_scale_chunk.json` and
`B8b_scale_chunk.json`. They include per-input hashes and fixed-scale errors
for 1/2/4/8/16/32 intervals. Rendering and generation-aware attribution
remain SPECIFIED. Do not interpret the JSON as an image-quality result.

```powershell
python reference/temporal/audit/scale_chunk_probe.py --tc outputs/tc --run B8a --out outputs/tc/NEW_B8a_scale_chunk.json
```

Use B8a first; B8b only confirms the selected policy. Sweep chunks of 1, 2, 4, 8,
16, 32 intervals. For each, measure log-scale drift on co-visible **generations**;
without sidecars, label row-based results a proxy. Compare constant first scale,
median log-scale, and lifetime splits at 1%, 2%, 5% max-axis change. Do not choose
a policy using only center distance or parameter errors.

Write approximation PLYs to a fresh directory, render the same fixed cameras,
and compare to the unmodified PLY sequence using raw color and the **same frozen**
color correction. Refitting a color map per export could hide conversion errors.
Report fit/detail loss, added flicker, split-record count, encoded size estimate
and worst face/hand/clothes crop. Preserve original PLYs and hashes.

Proposed conversion budget (declare before running, not historical evidence):
mean/final fit and detail loss <=0.2 dB; added regional flicker <=0.5 in the report's
1e-3 units; no disappearance of active source generations. Review worst pairs
as well as the mean. If no policy passes, use a richer representation instead of
forcing fixed scales in training. Repeat with raw-color error to expose bias.

### G3 — Native PLY -> VGS correctness (SPECIFIED; exporter missing)

Build fixtures before touching the large take. Drive the production encoder and
decoder, never a separate Python implementation of the container. Keep signing
in the existing authoring library; do not copy keys into test output or prompts.

| Fixture | Required checks |
|---|---|
| One static splat; RGB primaries; anisotropic scales; rotations about each axis | Position/units, log-to-linear, sigmoid, wxyz/xyzw, SH plane order; SH degrees 0/1/2/3 as supported |
| Linear and accelerating motion, 1/4/32 intervals | Every source sample, quarter/half/three-quarter subframes; expose V01/V02; compare against declared interpolation oracle |
| Two identities sharing a row at disjoint times | Separate records/lifetimes or explicit generation-aware encoding; never travel between unrelated surfaces |
| Birth/death at first, middle and final interval | Half-open intervals, boundary +/-epsilon, no ghost before birth, no duplicate active record |
| Variable scale and variable SH | Exercise chosen scale policy; do not silently freeze varying SH; quantify declared approximation |
| 1, 2, 32, 33, 64 source frames | Chunk overlap/end sample policy; no missing/duplicated displayed frames; empty/inactive records handled |
| 25, 30, 50, 30000/1001 Hz; source offset 45 | Exact rational timing, seek and final-frame hold; no accumulated drift |
| Raw `.pgs` vs compressed `.vgs` | Identical decoded logical arrays (entropy compression itself is lossless) |
| Page rows 1024 and 65536; chunks near 255 intervals | Attribute/lifetime/rank boundaries; reject >255 in current profile |
| Inconsistent counts/schema, NaN, missing frame, invalid quaternion | Explicit error before publishing output; no partial file accepted as complete |

Use packer-derived error bounds (half quantization step in its declared domain),
not arbitrary zero float tolerances. Identity/lifetimes/counts/timebase must be
exact. Include finite checks, normalized quaternions, q/-q equivalence, and negative
scales rejected before logarithms. Test bounds with **anisotropic splat extents**
if consumers cull by bounds; center-only bounds are not full render bounds.

G3 is blocked until a native sequence writer exists. Do not describe renaming or
copying PLY files (`export_seq.py`) as VGS conversion. V01/V02 need an explicit
representation decision, not a silent compatibility change.

### G4 — Real round trip and playback (SPECIFIED, depends on G3)

Encode B8a 45-76; decode at every source frame and subframes from the native and
WASM decoders. Compare decoded attributes under the declared quantization budget,
then render original vs decoded with identical cameras/background/PPISP policy.
Use G2's image budgets. Check both SH-enabled and base-color paths, all layers,
sequential/reverse/random seeks, loop and ping-pong around every chunk boundary.
No stale records or teleportation at lifetime changes. Measure file size,
peak memory, encode/decode time and p50/p95 frame time including chunk loads.
Target device/render budget must be named before declaring real-time readiness.

Run the existing VGS `ctest` suite on its configured fixture in an isolated build
directory after writer changes. A skipped fixture is SKIP, not PASS; the existing
roundtrip validates MINT import, not the new PLY path. Preserve legacy imports.
Never rebuild shared user build directories or modify current plugin/USD work.

### G5 — Detail and training robustness (READY runner; lower priority than G1-G3)

Two predeclared batches are implemented by `run_battery.py`:

| Batch | Jobs | Purpose |
|---|---|---|
| `detail` | B8 baseline 45-64; 8000 instead of 4000 steps; SH LR 0.00005 instead of 0.000025 | Separate budget from SH learning-rate changes |
| `replicates` | Three B8 runs 45-76, same recipe | Estimate variability (seeds are clock-driven, not controlled paired seeds) |

`detail` changes one factor per candidate. First-frame steps stay 8000. Extending
the per-frame budget also stretches schedules; call this a budget/schedule test,
not an isolated convergence proof. Suggested promotion rule: detail improves
>=0.2 dB, fit loses <=0.2 dB, coverage loses <=2 percentage points vs its baseline,
and flicker <=9.5. Confirm any promoted candidate with repetitions before choosing
it; the observed 15% flicker spread makes single-run small differences inconclusive.

Execution note (2026-09-27): `detail` was launched with prefix `B9_20260927`.
The orchestration script writes `outputs/tc/B9_20260927_battery/status.json` as
each phase changes and keeps training/evaluation logs in that folder and the
individual `outputs/tc/B9_20260927_*` runs. Check status before considering any
retry. Do not start the `replicates` command while this battery is active.
During the first training job, an evaluator smoke test found that a longer `.seq`
must be sliced to the requested frame range. `evaluate_run.py` was corrected
before any B9 evaluation. The launch-time hash in `status.json` is therefore
superseded by `execution_correction.json` for that script; keep both files.
A B7b evaluator smoke run completed successfully; its output is
`outputs/tc/audit_20260927_02/evaluate_run_B7b_smoke.json`. Its values were
not used to select a new recipe.
The `replicates` batch was queued with prefix `B8R_20260927` using
`queue_after.py` (background PID 39596). Its state is
`outputs/tc/B8R_20260927_queue_status.json`. It starts only after B9 reaches
`COMPLETE`; if B9 reports `ERROR`, it records `SKIPPED_AFTER_ERROR` and does not
start GPU work. Its own batch status will be
`outputs/tc/B8R_20260927_battery/status.json` once launched.

For `replicates`, report every result, mean, SD and range, including per-frame/pair
worst cases. Do not repeatedly rerun until a seed passes. Current practical targets:
mean fit >=30.5, final >=30.0, final coverage >=88%, flicker <=9.5; the original
stretch goal is fit >=30.5 throughout and flicker <=8. Do not relabel one as the other.

Commands from the Spirula root (first is a dry plan; second does work):

```powershell
python reference/temporal/audit/run_battery.py --batch detail --prefix B9_20260927
python reference/temporal/audit/run_battery.py --batch detail --prefix B9_20260927 --execute
python reference/temporal/audit/run_battery.py --batch replicates --prefix B8R_20260927 --execute
```

Read-only input preflight, without training or output creation:

```powershell
& reference/temporal/audit/train_one.ps1 -Name PREFLIGHT_ONLY -Last 64 -ValidateOnly
```

Run only the selected batch, not both in parallel. Each training job and its
evaluation finish before the next starts. Outputs:
`outputs/tc/<prefix>_battery/status.json`, per-job metrics and logs, plus unique
training folders. An exclusive cooperative lock covers training AND evaluation;
the training wrapper also rejects an existing Spirula process. Other tools do
not honor this lock, so do not launch independent GPU work while it runs.

This runner uses the current `outputs/tc/bin/spirula.exe` and records its hash;
it **does not build changes**. To test a fix, build `build_tc` with the established
VS2022/CUDA12.8 workflow, copy the executable only while idle, and record build
provenance. The evaluation still depends on existing `outputs/tc/evalply.ps1` and
`common.ps1`; hashes are recorded. Per-run `<name>.inputs.json` records the exact
argument list, init/PPISP/warp/birth hashes and image/mask/sparse size/mtime inventory.
The dataset inventory is not a full content hash: freeze the dataset during a run;
hash its contents before claiming exact reproducibility across mutable copies.
Do not copy all old scripts or regenerate old reference renders indiscriminately.
GPU execution of this new runner is untested; parser/import/plan/input-preflight
checks passed. A first runtime error should stop the batch.

### G6 — Uniform reference, coverage bias, second take (SPECIFIED)

- One Forge recipe across 45-76, fixed PPISP/cameras/init policy recorded. Never
  mix two Forge recipes and call it a controlled comparison. Preserve the old
  reference and label the new one. Record time as well as quality.
- Coverage uses the same sparse points that births target. Add a held-out subset
  of candidate points (partition by spatial cells) plus rendered alpha/mask
  coverage and face/hand/clothes crops. Do not optimize solely for that sparse
  coverage number; nearby splat centers do not guarantee correct visible surface.
- Deterministic evaluation camera IDs and image resolution, rather than replacement
  sampling and content matching. Record missing/duplicate views. Test raw-color
  drift as well as corrected fit. Reuse the same camera subset across comparisons.
- Second take: ask the owner to select an available take with faster motion,
  occlusion and weak texture. Dataset preparation is a prerequisite, not an assumed
  path. Run baseline and chosen candidate with the same setup and at least three
  repetitions if making a robustness claim. Include longer duration to exercise
  free-row exhaustion and generation reuse after history eviction.

## 5. Minimal-token execution protocol

For the initial audit: no agents, no full build, no training, real host/native
probes plus existing PLY reads. Later build/training activity is in section 8.
Full compiler/probe outputs and hashes went to disk.

For the next model:

1. Read sections 1, 2, 4's relevant gate, and this section. Inspect only the functions
   a failed test names. The historical report is reference material, not a prompt
   to reload. No sub-agents are needed for watching jobs.
2. Choose READY work whose prerequisites pass. For SPECIFIED work, implement its
   fixture/hook first and record `NOT_IMPLEMENTED` until it exists. Never treat a
   CPU shim pass as CUDA/Vulkan or render validation, or PLY layout as identity proof.
3. Run one script for the complete selected battery. Use the process completion
   mechanism when available. Do not poll every few seconds or keep an LLM turn
   open just to watch iteration counters. If detached execution is needed on
   Windows, use `Start-Process -WindowStyle Hidden`, redirect stdout/stderr to
   files and record the PID. End with the saved status path; resume on completion
   or when the user asks. Process waiting is not model reasoning.
4. Read only `status.json` / `summary.json` at a meaningful checkpoint. On ERROR,
   read the last 40 lines of the named log, fix that cause, and stop automatic
   expansion to more experiments. Silence in a log is not proof of a hung job.
5. Reuse completed artifacts only when source/input/executable/evaluator hashes
   match. Training randomness means a repetition is a new run, not a cache hit.
   Use unique names; runners refuse overwrite. Never run the old `window.ps1`
   on an existing name: it recursively deletes that output directory.
6. No automatic restart after partial training: temporal resume is unsupported.
   Preserve partial files. A failed evaluation can be retried independently:

   ```powershell
   python reference/temporal/audit/evaluate_run.py --run UNIQUE_RUN --last 64 --out outputs/tc/UNIQUE_RUN_metrics_retry.json
   ```

   Check the run's `.seq` and expected files first. To continue a batch after one
   failure, explicitly schedule only the missing jobs; do not retrain successful
   ones. Evaluation caches are valid only with unchanged inputs and evaluator.
7. At a gate boundary append one table: ID, changed factor, outcome, artifact path,
   limitation, next action. Leave full logs out of Markdown. Update the current
   decision in the historical report only if evidence changes it.
8. Compact handover: `HEAD/exe hash; batch + output folder; completed IDs; active
   PID/status; failed prerequisite; next command`. Do not paste old transcripts,
   per-iteration logs, every image or every PLY property into the context.

CPU audit completion is not production approval. The immediate next work is G1's
absence/generation contract and G2/G3's representation decision; G5 is prepared
but should not consume GPU merely because the scripts are ready.

## 6. Proposed changes, in implementation order

This was the proposal table from the initial audit. The trainer P0 changes were
subsequently implemented and tested as described in section 8; codec changes
remain proposals. Keep quality comparisons to one declared factor at a time.

| Priority | Change | Files / integration point | Evidence and acceptance |
|---|---|---|---|
| P0 | Add each accepted birth to the gap search, with its new position; keep old and new candidates searchable | `EngineTemporal.cpp::engine_temporal_birth` | H05 reproduced duplicate allocation. H05 + G1.3 must pass, including adjacent grid cells and budget limits. Do not just insert a row index whose stored position is still the old one. |
| P0 | Define an explicit absence/lifetime gate for unborn generations; exclude them from rendering, optimization and temporal smoothing in older frames | `EngineTemporal.{h,cpp}`, engine optimizer/render integration as needed | H02/H07 show why low alpha alone fails. G1.1/G1.2 must show no prebirth pixels or reactivation. Do not use `-infinity` logits as an untested substitute. |
| P0 | Keep older held snapshots semantically fixed; reset optimizer history only where a row is actually repurposed, or prove it is unreachable behind the absence gate | `engine_temporal_birth`, per-slot state | H01/H04. Do not reset Adam for all entering warm-start splats: Wf/Wq already showed that is harmful. Check shared scale/SH moments and per-splat bias counters as well as means/DC. |
| P0 | Emit generation events and frame/time/coordinate metadata during training; preserve them when exporting/copied PLY sequences | `TrainerCore.cpp::advance_window`, temporal state, `export_seq.py` | H09; row reuse is expected, not something to ban. G1.4 and G3 must reconstruct identities without alpha-based guesses. Use sparse event records, not a full duplicated attribute dump per frame. |
| P1 | Validate inputs and fail explicitly when requested warp/birth files are missing, malformed or nonfinite; allow fallback only through an explicit policy | `TrainerCore.cpp::advance_window` and temporal config | Current missing warp falls back to extrapolation; missing birth file silently gives zero births. G1.5; record any intentional fallback in the manifest. |
| P1 | Add a native sequence-input path to the VGS authoring library, reusing its writer/signing/container code | VGS encoder API and internal source construction, after reading that repo's rules | Existing API imports MINT. First pass G3's one-interval correctness baseline; then optimize size using G2/G4. Do not implement a second encoder in Python. |
| P1 | Choose a compatible position representation and a measured scale policy | VGS authoring representation; decoder only if a new encoding is declared | V01/V02 and B8 scale drift. Never globally replace `r` with interval alpha for encoding 0 without a legacy compatibility decision and regressions. |
| P2 | Add an explicit reproducible seed and deterministic evaluation camera selection | Trainer RNG/config and eval loader | Clock-driven runs and sampled-with-replacement cameras mix training/eval variance. Record all RNG streams; test repeatability before calling two runs a paired experiment. |

Changes **not justified yet**: freezing all scales, removing higher-order SH,
increasing all training budgets, reviving the global opacity boost, or replacing
the whole temporal algorithm. Keep B8's reduced scale LR until representation and
image tests show a better option. One-interval VGS chunks are a correctness baseline,
not automatically the best production layout.

Suggested next-model instruction:

> Read TEMPORAL_VGS_TEST_PLAN.md sections 1-3 and 6. Implement P0 birth spacing
> first and rerun H05/G1.3 using a new audit output folder. Then design and test
> the absence/generation contract before GPU training. Keep B8 outputs untouched.
> Use section 5's token protocol; report only the gate table and exact next command.

## 8. Execution update: B8R, B10 and birth corrections (2026-09-27)

B8R completed all three 45-76 repetitions. Its `status.json` and per-run metrics
are in `outputs/tc/B8R_20260927_battery/`. All used the original B8 executable.

| Run | Fit mean/final dB | Detail dB | Flicker | Coverage at 76 |
|---|---:|---:|---:|---:|
| B8R repeat1 | 30.840/30.563 | 35.897 | 7.778 | 90.41% |
| B8R repeat2 | 30.842/30.523 | 35.911 | 7.695 | 90.95% |
| B8R repeat3 | 30.879/30.634 | 35.905 | 7.304 | 90.30% |

The flicker range is 0.473 on these three runs; including historical B8b (8.87)
shows that a longer-run upper tail remains possible. The B9 fixed-camera sheet
`outputs/tc/audit_20260927_02/B9_worst_pairs_H2_P10.png` compares frames
47/48/49/56/57/58 in camera `SMN_V1_H2_P10` across video, B9 control, 8k,
SH x2 and B8R repeat1. Generated from cached renders by `pair_sheet.py`; no new
GPU work. The resized sheet is a visual check, not a quantitative face/hand test.
On this camera the 8k render becomes visibly brighter and washed out from frame
56 to 57 across both subject and background, coinciding with its worst pair.
The control's 47-49 changes are concentrated more around high-contrast lights
and background; these are visual observations, not causal attribution. Check
other fixed cameras and raw-color drift before changing training based on them.

B10 is RUNNING: three serial 45-76 repetitions at 8000 steps per later frame,
original B8 executable SHA256 `41c0996ccc7343a51279e5f2ebf133b8ead14c55adefdf7be39fecfb0d0fefbe`.
Read `outputs/tc/B10_20260927_battery/status.json`. Its runner automatically
trains then evaluates each run; do not launch another GPU job meanwhile. Compare
all three B10 results to B8R using the same metrics and worst-pair distribution.
B9's +0.190 dB detail was below the declared +0.2 dB threshold, so B10 is a
confirmation experiment, not an already promoted recipe.

Spirula production changes now present in this working tree: accepted births
enter the gap grid; reuse requires opacity below the 1/255 raster cutoff in all
resident frames; old per-frame means/quaternion/DC are preserved; moments of a
reused row are cleared in every resident slot; generation counters advance on
reuse and smoothing does not span a generation boundary. `TrainerCore` writes
`frames/birth_events.tsv` as `frame<TAB>row<TAB>generation` and rejects missing,
truncated, trailing or nonfinite warp/birth inputs when those directories are
configured. `export_seq.py` carries the event sidecar for a single temporal run.
The sidecar does not yet include complete timebase/coordinate metadata, and the
low-opacity criterion is not a proven permanent visibility/gradient mask.

Focused current-source audit: `outputs/tc/audit_20260927_warp_valid_v3/`
has 16/16 temporal H contracts PASS, including second reuse and degenerate warp
node exclusion; V01/V02 remain
expected legacy decoder mismatches. CUDA `build_tc/spirula.exe` compiled. A copied
candidate `outputs/tc/bin/spirula_birth_v2.exe` (SHA256
`68f2436ba9029316770ae73e172f12af14884853d09bceef300f5cbc95198b84`)
is isolated from B10's exe. The B11 candidate also skips non-unit warp nodes:
10 of 124,821 nodes in this take's 31 binary warp files have quaternion norm
near zero. Their exclusion prevents undefined orientation if they bind a splat;
its quality effect must be measured in B11. Source binary scan and H16 cover
the finding; the old B10 executable is unchanged.
Vulkan source compiled through the link stage, but `build_vulkan` failed to link
both `vk_sortscan_test` and the `spirula` target on unresolved `__std_*` runtime
symbols. Logs: `outputs/tc/audit_20260927_birth_lifetime/build_vulkan*.log`.
Vulkan runtime parity is unverified; do not count this as a backend pass.

B11 is WAITING on B10 `COMPLETE`, via hidden queue PID 8760 and
`outputs/tc/B11_20260927_queue_status.json`. It will run one 45-76 B8-recipe
trial with the corrected CUDA executable, then evaluate it. Its own status will
be `outputs/tc/B11_20260927_battery/status.json`; the queue skips B11 if B10
errors and times out after 12 hours. Do not mistake this one trial for proof of
all G1 render/optimizer contracts. The modified runners pass Python syntax and
plan-only checks; the B11 path is pending actual execution.

After completion, read only the two `status.json` files and their compact metrics.
If either says ERROR, inspect that run's driver/eval log tail and retain partial
artifacts. Then run G1.1/G1.2 with a tiny real-render fixture, correct the Vulkan
toolchain mismatch, and implement the native VGS sequence writer with G3 fixtures.
G2 matched renders and G4 round trip remain blocked by the representation choice.

## 7. B9 interpretation (2026-09-27)

B9 completed successfully; all three training and evaluation jobs produced metrics.
B8R was still training repeat1 when this interpretation was written. Do not infer
replicate statistics from that incomplete battery. Source: the three
`outputs/tc/B9_20260927_battery/*_metrics.json` and training logs.

| 45-64 run | Fit mean / final dB | Detail dB | Flicker | Coverage at 64 | Training time |
|---|---|---|---|---|---|
| B8 recipe control | 30.969 / 30.901 | 36.056 | 9.834 | 92.38% | 25:18 |
| 8000 steps/frame | 31.380 / 31.486 | 36.246 | 7.316 | 92.06% | 43:33 |
| SH LR x2 | 31.044 / 31.017 | 36.120 | 7.725 | 92.60% | 23:51 |

The 8000-step candidate improves mean fit by 0.411 dB and final fit by 0.585 dB,
with 0.32 percentage points less coverage and 72% more measured training time.
Detail improves by 0.190 dB, **below** the predeclared >=0.2 dB promotion threshold.
Do not round it into a pass. This is a promising fit candidate, not a validated
replacement. The budget also changes the schedule duration.

Doubling SH LR yields only +0.075 dB fit and +0.064 dB detail. Its flicker reduction
is not independently established: the control's worst pairs 47->48 and 48->49
are 33.89 and 34.20; the 8k run's worst are 56->57 and 57->58 at 14.91 and 14.66.
The mean alone hides where failures move. One run each cannot separate seed/eval
variation from the parameter change. Neither candidate passes the detail promotion
criterion as written.

Next actions: finish the queued B8R runs; inspect fixed-camera crops of the worst
pairs and use a deterministic shared camera list; then confirm 8k on the full
45-76 span with repetitions if its additional cost is acceptable. Keep SH LR x2
lower priority. Preserve B8 as the reference until confirmation.

VGS readiness did not improve merely by training B9: the birth/absence/generation
and legacy interpolation blockers remain. The scale sweep JSONs show substantial
fixed-scale parameter errors, with extreme tails. They include background and use
row identity as a proxy; they cannot quantify visible conversion loss. Run G2's
matched-render comparison before choosing a constant-scale or split-record policy.
No production algorithm change or additional training was launched during this
interpretation.

## 9. C12 execution and handoff (2026-09-27; supersedes earlier pending states)

B10 and B11 are COMPLETE. Numerical results are in TEMPORAL_TRAINING.md section
11 and the battery status files. B11 passes mean >=30.5, final >=30.0,
flicker <=9.5, final coverage >=88%. It is the corrected-birth reference.

Completed gates:

- CUDA birth render/optimizer fixture: 8/8 PASS. See
  `outputs/tc/birth_gpu_validation.log` and
  `src/backend/tests/engine/engine_temporal_birth.cpp`.
- Native codec self-test: source samples, chunk overlap, antipodal quaternions,
  generation separation, seek order PASS.
- Synthetic four-mode WASM/WebGL2 test: PASS on hardware RTX 4070. Evidence in
  `outputs/tc/C12_fixture_v2/web_metrics.json` and per-mode `metrics.json`.
  Initial fragment-output indexing and unused legacy dictionary omissions were
  corrected before this pass. This is why compile-only validation was insufficient.
- VGS regression CTest: 11/11 PASS, including MINT roundtrip. Logs live in
  VGSFileFormat `temporal_ctest.log`. Default decoder accepts encoding 0 and
  rejects experimental encoding 1 as intended; WASM bundle key-leak check PASS.

The hidden C12 runner is active at `outputs/tc/C12_20260927/status.json`.
It has frozen the B11 reference and runs modes serially, then matched renders,
then Chrome. It records phase logs, executable hashes, decoded PLYs, raw GPU
buffers, compressed `.vgs`, `render_metrics.json` and `web_metrics.json`.
It stops on failure and preserves partial results. No training is repeated.

Read state with minimum token cost:

```powershell
python reference/temporal/audit/codec_status.py
```

Do not poll training logs or dump manifests. On ERROR read only the named phase
log tail (30 lines) and runner stderr. Do not rerun completed training or reuse
an existing codec output directory. Fix the failed stage, retain its evidence,
and use a new output for retries. Tests execute locally without model calls;
token use is limited to this compact status and targeted failure diagnosis.
The runner shares the training GPU lock. Never launch another GPU job beside it.

Comparison policy: samples are a lossless control; compare legacy/adaptive/
predictive on the exact same reference. Legacy uses existing encoding 0 with
one held frame/chunk and deliberately simple LUT/SH codebooks. Its quality and
compression are not a bound on what optimized VGS authoring can achieve.
Adaptive and predictive use experimental encoding 1, four frames/chunk, complete
attributes and generation lifetimes. No production VGS/MINT contract is changed.
Prefer current VGS unless measured benefit justifies a backward-compatible
implementation decision; a smaller experimental file alone is insufficient.

Render budgets are <=0.2 dB loss in mean/final/detail and <=0.5 added flicker.
Use common fixed cameras, ground-truth equality and one reference-derived color
fit shared by all variants. Samples must preserve exact PLY hashes. Browser
reports decode slices, CPU packing, upload completion, allocated GPU bytes,
native evaluation and seeks. Decoder timing uses real VGS entropy decoding.

Remaining limitations / promotion gates:

- Vulkan runtime parity is still blocked by the previously recorded linker issue.
- Timebase 1/30 is explicit benchmark timing, not independently verified capture
  timing. Frame-domain comparison is valid; verify source FPS before delivery.
- Web measurements exclude scene rendering/sorting and legacy basis-pass GPU
  evaluation; no end-to-end viewer FPS claim is justified. Integrate both paths
  into the same renderer before choosing production representation.
- GPU oracle checks first chunk at 0.5; expand to all chunk boundaries, generation
  births/deaths, last tick and random seeks before promotion. Seek byte-count
  checks alone do not establish value parity. Native CPU fixtures cover a subset.
- Matched image metrics evaluate source-frame times only. They do not measure
  subframe visual discontinuity in the held-frame legacy baseline. Render the
  same intermediate times and camera motion in the final viewer before claiming
  equal temporal quality or choosing a codec for 60/90 Hz playback.
- Benchmark sample counts are small; do repeated warm/cold timing, mobile/XR
  and actual viewer memory tests only after visual acceptance.
- One corrected B11 run and one take do not establish general robustness.

Implementation details and exact experimental layout are in VGSFileFormat
`experiments/temporal/README.md`. Source changes are limited to Spirula training/
audit work and opt-in VGS experiment support. Web viewer source is read-only.
