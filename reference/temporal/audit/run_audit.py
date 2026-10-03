"""CPU-only audit: production host code, native VGS decoder, existing PLY artifacts."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def run(command, log, cwd):
    with open(log, "w", encoding="utf-8") as f:
        p = subprocess.run([str(x) for x in command], cwd=cwd, stdout=f, stderr=subprocess.STDOUT)
    return p.returncode


def native_probes(out, vgs):
    compiler = shutil.which("cl")
    if not compiler:
        raise RuntimeError("Run in a VS 2022 x64 developer environment (cl not found).")
    common = [compiler, "/nologo", "/std:c++17", "/EHsc", "/MD", "/O2"]
    probes = [("temporal", common + [f"/I{HERE / 'shim'}", f"/I{REPO / 'src'}",
               HERE / "temporal_probe.cpp"]) ]
    lib = vgs / "build_tests/decoder/Release/vgsdecoder.lib"
    probes.append(("vgs", common + [f"/I{vgs / 'core/include/vgs'}", f"/I{vgs / 'core/crypto'}",
                   HERE / "vgs_probe.cpp", vgs / "core/src/vgsframe.cpp", lib]))
    rows = []
    for name, command in probes:
        exe = out / (name + "_probe.exe")
        command += [f"/Fe{exe}"]
        if run(command, out / (name + "_build.log"), out):
            raise RuntimeError(f"{name} build failed; read {name}_build.log")
        log = out / (name + "_results.jsonl")
        code = run([exe], log, out)
        parsed = [json.loads(line) for line in log.read_text().splitlines() if line.startswith("{")]
        if not parsed or code not in (0, 1):
            raise RuntimeError(f"{name} probe failed unexpectedly, exit {code}")
        rows.extend(parsed)
    return rows


def read_ply(path):
    import numpy as np
    with open(path, "rb") as f:
        lines = []
        while True:
            line = f.readline()
            if not line:
                raise ValueError(f"Incomplete PLY header: {path}")
            lines.append(line.decode("ascii").strip())
            if lines[-1] == "end_header":
                break
        if "format binary_little_endian 1.0" not in lines:
            raise ValueError("Only binary little-endian float PLY is supported")
        elements = [x for x in lines if x.startswith("element ")]
        if len(elements) != 1 or not elements[0].startswith("element vertex "):
            raise ValueError("Expected vertex-only PLY")
        n = int(elements[0].split()[2])
        props = [x.split() for x in lines if x.startswith("property ")]
        if any(len(x) != 3 or x[1] != "float" for x in props):
            raise ValueError("Expected float properties")
        names = [x[2] for x in props]
        a = np.fromfile(f, dtype="<f4")
        if len(a) != n * len(names):
            raise ValueError("PLY length mismatch")
    return names, a.reshape(n, len(names))


def artifacts(tc, names, out):
    import numpy as np
    runs, inputs = [], []
    for name in names:
        seq = tc / (name + ".seq")
        mapping = [line.split() for line in seq.read_text().splitlines() if line.strip()]
        if len(mapping) < 2:
            raise ValueError(f"Too few frames in {seq}")
        frames = [int(r[0]) for r in mapping]
        if frames != list(range(frames[0], frames[-1] + 1)):
            raise ValueError(f"Non-contiguous frame mapping in {seq}")
        prev = props = None
        stats, pairs, hashes = [], [], []
        for frame, run_name, index in mapping:
            path = tc / run_name / "frames" / f"{int(index):03d}" / "splat.ply"
            names_ply, a = read_ply(path)
            if props is not None and (props != names_ply or a.shape != prev.shape):
                raise ValueError(f"Layout/count changed at {path}")
            props = names_ply
            ix = lambda cols: [props.index(c) for c in cols]
            pos = a[:, ix(["x", "y", "z"])]
            logs = a[:, ix([f"scale_{i}" for i in range(3)])]
            q = a[:, ix([f"rot_{i}" for i in range(4)])]
            logits = a[:, props.index("opacity")]
            alpha = 1 / (1 + np.exp(-np.clip(logits, -80, 80)))
            qnorm = np.linalg.norm(q, axis=1)
            row = {"frame": int(frame), "rows": len(a), "finite": bool(np.isfinite(a).all()),
                   "zero_quaternions": int((qnorm < 1e-8).sum()),
                   "qnorm_max_deviation": float(np.max(abs(qnorm - 1))),
                   "live_01": int((alpha > .1).sum()),
                   "reusable_but_above_raster_cutoff": int(((alpha < .005) & (alpha > 1 / 255)).sum())}
            stats.append(row)
            if prev is not None:
                old_alpha = 1 / (1 + np.exp(-np.clip(prev[:, props.index("opacity")], -80, 80)))
                both = (alpha > .1) & (old_alpha > .1)
                delta = np.max(abs(logs - prev[:, ix([f"scale_{i}" for i in range(3)])]), axis=1)
                displacement = np.linalg.norm(pos - prev[:, ix(["x", "y", "z"])] , axis=1)
                sh_idx = [i for i, p in enumerate(props) if p.startswith("f_rest_")]
                sh_delta = abs(a[:, sh_idx] - prev[:, sh_idx]) if sh_idx else np.zeros((len(a), 1))
                pairs.append({"frame": int(frame), "co_visible_rows": int(both.sum()),
                              "scale_log_delta_p50": float(np.median(delta[both])) if both.any() else None,
                              "scale_log_delta_p95": float(np.quantile(delta[both], .95)) if both.any() else None,
                              "scale_changed_rows": int((delta > 1e-6).sum()),
                              "sh_abs_delta_p95": float(np.quantile(sh_delta[both], .95)) if both.any() else None,
                              "co_visible_jump_gt_5cm": int((both & (displacement > .05)).sum()),
                              "low_to_live_rows": int(((old_alpha < .005) & (alpha > .1)).sum())})
            hashes.append({"frame": int(frame), "path": str(path), "sha256": sha(path)})
            prev = a
        detail = {"run": name, "frames": stats, "pairs": pairs, "inputs": hashes,
                  "limits": "Row index is not a verified lifetime ID. All rows, including background; jumps are diagnostic, not identity proof."}
        (out / f"{name}_artifacts.json").write_text(json.dumps(detail, indent=2), encoding="utf-8")
        runs.append({"run": name, "frames": len(stats), "rows": stats[0]["rows"],
                     "finite": all(r["finite"] and r["zero_quaternions"] == 0 for r in stats),
                     "scale_changed_pairs": sum(p["scale_changed_rows"] > 0 for p in pairs),
                     "median_pair_scale_log_p50": float(np.median([p["scale_log_delta_p50"] for p in pairs if p["scale_log_delta_p50"] is not None])),
                     "low_to_live_transitions": sum(p["low_to_live_rows"] for p in pairs),
                     "max_reusable_visible_rows": max(r["reusable_but_above_raster_cutoff"] for r in stats)})
        inputs.extend(hashes)
    return runs, inputs


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--vgs-repo", type=Path, required=True)
    p.add_argument("--tc", type=Path, default=REPO / "outputs/tc")
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--runs", nargs="*", default=["B8a", "B8b"])
    args = p.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    manifest = {"utc": dt.datetime.now(dt.timezone.utc).isoformat(), "command": sys.argv,
                "scope": "CPU production host logic with mock transfers; current VGS frame source + existing codec library; no GPU or renderer validation",
                "files": {}}
    sources = [REPO / "src/engine/EngineTemporal.cpp", REPO / "src/engine/EngineTemporal.h",
               args.vgs_repo / "core/src/vgsframe.cpp", args.vgs_repo / "core/src/vgsencode.cpp",
               args.vgs_repo / "build_tests/decoder/Release/vgsdecoder.lib", *HERE.glob("*.cpp"),
               *HERE.glob("*.py"), * (HERE / "shim").rglob("*.h")]
    for path in sources:
        manifest["files"][str(path.resolve())] = sha(path)
    for label, repo in [("spirula", REPO), ("vgs", args.vgs_repo)]:
        manifest[label + "_head"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
        manifest[label + "_status"] = subprocess.check_output(["git", "status", "--short"], cwd=repo, text=True)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    try:
        tests = native_probes(out, args.vgs_repo.resolve())
        runs, _ = artifacts(args.tc.resolve(), args.runs, out)
        summary = {"status": "FINDINGS" if any(t["status"] == "FAIL" for t in tests) else "PASS",
                   "seconds": round(time.monotonic() - started, 2), "tests": tests, "artifacts": runs}
        (out / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        lines = ["# Temporal/VGS audit results", "", f"Status: {summary['status']}. CPU only.", "",
                 "| Test | Result | Observed | Expected |", "|---|---|---:|---:|"]
        lines += [f"| {t['id']} | {t['status']} | {t['observed']:.7g} | {t['expected']:.7g} |" for t in tests]
        lines += ["", "Artifact summaries (all rows, not subject-only):", "", "```json", json.dumps(runs, indent=2), "```"]
        (out / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(json.dumps({"status": summary["status"], "tests": len(tests),
                          "failed_contracts": sum(t["status"] == "FAIL" for t in tests), "out": str(out)}))
    except Exception as exc:
        (out / "summary.json").write_text(json.dumps({"status": "ERROR", "error": str(exc)}, indent=2), encoding="utf-8")
        raise


if __name__ == "__main__":
    main()
