# Chunk frames without dead rows — design v3 (2026-10-05, for review)

Goal: a published chunk frame holds the subject's splats and nothing the frame
does not show, as a static Forge frame does. No code before this is agreed.

Constraints: the room is **not** removed in training (an alpha loss outside the
mask caused false transparency; Forge trains the room and prunes it after).
Hiding rows after training is not a fix. Measured facts below are from
`TEMPORAL_TRAINING.md` 5.17 and the review of 2026-10-05.

## 1. What is wrong today (FC4, VIDEOTIKI 45-76)

Every frame of the chunk has 395k rows. Published, 241-285k are shown; 90k are
never shown in any frame; frame 0 also holds 64k rows shown only later. In a
viewer's centre view these are the room's columns and floor and a haze around
the people (the user's screenshot of 2026-10-05). They come from:

1. **The seed is the static model unpruned**: it keeps the room (89k rows by
   Forge's prune, 4.1 below). It has no dead rows (0 below opacity 1/255, 385
   below 0.1 mm): static MCMC training relocates the splats that die.
2. **The room is trained per frame for the whole chunk** (per-frame slot,
   Adam state, smoothing), then the chunk prune writes it dead (logit -20) in
   every frame so rows stay aligned.
3. **Splats die in the chunk and stay dead**: densification is off, so nothing
   relocates them. Training frame 0 alone kills 51k subject rows (opacity below
   1/255; 17 % of the subject) and shrinks 10k more below 0.1 mm; 8.7k room
   rows die too. These dead rows are what births take: a row born at frame 20
   is a dead row in frames 0-19. Why so many die in frame 0 is not known yet.
4. Deaths inside the chunk: a row that dies stays a dead row in later frames
   (17k at frame 15, 20k at frame 31). Gracia's records have the same life
   cycle (records per chunk 249-285k, active per sample 175-233k).

Not chunk-specific, left for later: we show more splats than Gracia (Forge per
frame even more, 303-336k), in layers that do contribute (removing them costs
0.75 dB); and faint splats at the silhouette grow along the chunk (4.4k -> 10.4k
shown, static ~6k).

## 2. Design

### 2.1 Seed split by Forge's own prune
Forge prunes the seed (`PruneGaussianFile`) in two steps, using
`GaussianPrunePasses`:

- **Room** = rows removed by the passes that judge by distance and position:
  sparse support (> 15 cm from the subject envelope), geometry (camera
  cylinder, floor, top), floor ellipsoid, maximum diameter.
- **Junk next to the subject** = rows removed by the remaining passes (mask
  consensus, isolation, clusters, SOR) on what is left: dropped, not kept as
  room. Kept static next to a moving person they would be a frozen ghost of
  the first frame's edges.
- **Subject** = the rest.
- Rows the static export drops (opacity < 1/255, dead scale) are dropped from
  both.

Forge writes `room.ply` and `subject.ply`; `GraciaChunkRows` already matches
rows between a PLY and its pruned version.

### 2.2 The room is a static context layer
Spirula loads `--temporal-room-ply` first: rows `[0, nr)`. They are rendered
and trained every step (so the subject keeps its opacity and depth order), with
one state shared by all frames: the live buffers, never copied to a slot. Per
frame slots, smoothing, births, locks and generations cover `[nr, n)` only
(`per_frame_fields` with an offset). This changes today's behaviour (each room
row has a state per frame); FS1 tests it. The room layer is never written to a
frame; spirula writes it once per chunk (`room.ply`, a working file) for the
next chunk.

### 2.3 The subject population grows
Open after 4.1: rows die inside the chunk (1.3), so births may find free rows
without growth, but every dead row is an invisible row in the frames until it
is reborn. What matters first is why 17 % of the subject dies in frame 0 and
whether a dead row should be reborn at once, as MCMC relocation does in a
static run. Growth as planned: births grow the subject range: the world
buffers are allocated for `max_num_splats` (`setData3DGS`) and
`cur_num_splats` grows inside them, as MCMC densification does. Slots are
allocated for the subject capacity from the start, so a growth copies nothing.
A birth still reuses a row dead in every frame of the window when there is one
(none, in practice: a row that died in the chunk was alive earlier).

Capacity: FC4 would need ~85k room + ~240k subject + ~96k births = ~420k,
above Forge's `--cap-max 395204`. Either a larger cap (slot memory scales with
the subject capacity, not the room) or fewer births; decided with FS1's
numbers.

### 2.4 Frames written by our own writer
`write_frame` today calls `engine_save_checkpoint(..., keep_all)`, which writes
every row. A PLY writer in our files writes frame k as subject rows
`[nr, n_k)`, `n_k` the range when it is written: frame 0 has no row born later;
the only invisible rows are those that died earlier in the chunk (0 at frame 0,
~20k at frame 31 if FC4's deaths hold). Upstream checkpoint code is untouched.

Open choice (the user's): those dead rows stay as rows (row = record, as now),
or each frame writes only its shown rows plus a record column (row,
generation), which is how Gracia's records work. The first keeps vgsplyseq's
row model; the second needs vgsplyseq to read the record column.

### 2.5 Between chunks
The next chunk starts from the last frame's live subject rows and the room
layer as it ended; Forge's near-subject passes run again on the subject part.

### 2.6 Forge's chunk prune
Stays: one decision per record on the subject rows. A killed record is a dead
row in every frame under the first choice of 2.4 (FS1 counts them), not written
under the second.

### 2.7 What changes where
- **Forge** (`graciachunk.cpp`): the two-step seed split, two files to spirula;
  recipe otherwise FC4's.
- **Spirula** (our files): room layer + subject offset in `EngineTemporal`,
  growth in `engine_temporal_birth`, the frame writer in `TrainerChunk.cpp`.
  Not yet checked: that the optimizer moments are also allocated for
  `max_num_splats`.
- **vgsplyseq**: frames whose row count grows (missing rows = not present).

## 3. How it is judged
1. Rows: per published frame, rows ~ splats shown; centre view without the
   room; invisible rows only from deaths.
2. Look: full-resolution crops of the glass, hands and face at frames 45, 52,
   60, 70, 76 against GT, Forge per frame and FC4; edges and hair against the
   room.
3. Brightness per frame (FC4: -6 % over the chunk; must not get worse).
4. Fit, detail, flicker, `.vgs` size, training time and GPU memory.

## 4. Order of work
1. **Offline: done 2026-10-05.** `GraciaChunk::splitSeed` (Forge, uncommitted)
   on FC4's seed: 395021 rows = 0 dead + 89063 room + 1599 next to the subject
   + 304359 subject, the same counts as Forge's static prune of that frame.
   Rendered apart: the room holds nothing of the people (only their contact
   shadows on the floor), the subject nothing of the room.
2. **Spirula**: room layer, subject offset, growth, frame writer; a test that
   a growth leaves written frames unchanged.
3. **Forge**: seed split. **vgsplyseq**: growing frames.
4. **FS1**: FC4's recipe with this, judged by section 3 against FC4.
