"""Start one serial GPU battery only after another has completed successfully."""
import argparse
import datetime as dt
import json
from pathlib import Path
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
TC = HERE.parents[2] / "outputs/tc"


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--after", type=Path, required=True)
    p.add_argument("--prefix", required=True)
    p.add_argument("--batch", choices=["replicates", "full8k", "birth_v2"], default="replicates")
    p.add_argument("--exe", type=Path)
    p.add_argument("--max-wait-hours", type=float, default=6)
    a = p.parse_args()
    status_path = TC / (a.prefix + "_queue_status.json")
    if status_path.exists():
        raise FileExistsError(status_path)
    status = {"state": "WAITING", "after": str(a.after.resolve()),
              "prefix": a.prefix, "utc": dt.datetime.now(dt.timezone.utc).isoformat()}

    def save():
        tmp = status_path.with_suffix(".tmp")
        tmp.write_text(json.dumps(status, indent=2), encoding="utf-8")
        tmp.replace(status_path)

    save()
    deadline = time.monotonic() + a.max_wait_hours * 3600
    while time.monotonic() < deadline:
        previous = json.loads(a.after.read_text(encoding="utf-8-sig"))
        if previous["status"] == "ERROR":
            status["state"] = "SKIPPED_AFTER_ERROR"
            save()
            return 1
        if previous["status"] == "COMPLETE":
            break
        time.sleep(60)
    else:
        status["state"] = "TIMEOUT"
        save()
        return 2
    status["state"] = "RUNNING"
    save()
    command = [sys.executable, str(HERE / "run_battery.py"), "--batch", a.batch,
               "--prefix", a.prefix, "--execute"]
    if a.exe:
        command += ["--exe", str(a.exe)]
    with open(TC / (a.prefix + "_queue_runner.log"), "w", encoding="utf-8") as log:
        code = subprocess.run(command, cwd=HERE.parents[2],
                              stdout=log, stderr=subprocess.STDOUT).returncode
    status["state"] = "COMPLETE" if code == 0 else "ERROR"
    status["exit_code"] = code
    save()
    return code


if __name__ == "__main__":
    raise SystemExit(main())
