"""Plan or run existing B8/detail recipes, serially; never overwrite an experiment."""
import argparse
import datetime as dt
import hashlib
import json
import msvcrt
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
TC = REPO / "outputs/tc"


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1024 * 1024), b""):
            h.update(b)
    return h.hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--batch", choices=["detail", "replicates", "full8k", "birth_v2"], required=True)
    p.add_argument("--prefix", required=True)
    p.add_argument("--exe", type=Path, default=TC / "bin/spirula.exe")
    p.add_argument("--execute", action="store_true")
    args = p.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.prefix):
        p.error("Use an alphanumeric prefix with underscores/hyphens")
    if args.batch == "detail":
        configs = [("base", 64, 4000, .000025), ("steps8k", 64, 8000, .000025),
                   ("sh2x", 64, 4000, .00005)]
    elif args.batch == "replicates":
        configs = [(f"repeat{i}", 76, 4000, .000025) for i in range(1, 4)]
    elif args.batch == "full8k":
        configs = [(f"repeat{i}", 76, 8000, .000025) for i in range(1, 4)]
    else:
        configs = [("trial", 76, 4000, .000025)]
    jobs = [{"name": args.prefix + "_" + tag, "last": last, "steps": steps, "sh_lr": lr}
            for tag, last, steps, lr in configs]
    if not args.execute:
        print(json.dumps({"mode": "PLAN_ONLY", "jobs": jobs}, indent=2))
        return
    out = TC / (args.prefix + "_battery")
    for job in jobs:
        for suffix in ("", ".seq", ".log", ".inputs.json"):
            if (TC / (job["name"] + suffix)).exists():
                raise FileExistsError(job["name"] + suffix)
        if list((TC / "q").glob(job["name"] + ".seq_*")):
            raise FileExistsError("Existing render cache for " + job["name"])
    out.mkdir(exist_ok=False)
    lock = open(TC / "temporal_audit_gpu.lock", "a+b")
    lock.seek(0)
    if lock.read(1) == b"":
        lock.write(b"0")
        lock.flush()
    lock.seek(0)
    msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
    state = {"status": "RUNNING", "jobs": jobs, "completed": [],
             "started_utc": dt.datetime.now(dt.timezone.utc).isoformat()}
    def save():
        tmp = out / "status.tmp"
        tmp.write_text(json.dumps(state, indent=2), encoding="utf-8")
        tmp.replace(out / "status.json")
    try:
        used = [args.exe, TC / "evalply.ps1", TC / "common.ps1",
                HERE.parent / "common.ps1", HERE.parent / "evaluate.py", HERE.parent / "population.py",
                HERE.parent / "flicker_lib.py", HERE.parent / "hull.py", *HERE.glob("*.py"), *HERE.glob("*.ps1")]
        state["sha256"] = {str(f): digest(f) for f in used}
        state["git_head"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip()
        for j in jobs:
            state["current"] = j["name"]
            state["phase"] = "TRAINING"
            save()
            command = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(HERE / "train_one.ps1"),
                       "-Name", j["name"], "-Last", str(j["last"]), "-FrameSteps", str(j["steps"]),
                       "-ShLr", str(j["sh_lr"]), "-ExePath", str(args.exe.resolve())]
            with open(out / (j["name"] + "_driver.log"), "w") as log:
                subprocess.run(command, cwd=REPO, stdout=log, stderr=subprocess.STDOUT, check=True)
            state["phase"] = "EVALUATING"
            save()
            target = out / (j["name"] + "_metrics.json")
            with open(out / (j["name"] + "_eval.log"), "w") as log:
                subprocess.run([sys.executable, str(HERE / "evaluate_run.py"), "--run", j["name"],
                                "--last", str(j["last"]), "--out", str(target)],
                               cwd=REPO, stdout=log, stderr=subprocess.STDOUT, check=True)
            metrics = json.loads(target.read_text())
            state["completed"].append({k: metrics[k] for k in
                                       ("run", "fit_mean", "fit_final", "detail_mean", "flicker", "coverage")})
            save()
        state["status"] = "COMPLETE"
    except BaseException as exc:
        state["status"] = "ERROR"
        state["error"] = str(exc)
        raise
    finally:
        save()
        lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
        lock.close()
    print(json.dumps({"status": state["status"], "out": str(out)}))


if __name__ == "__main__":
    main()
