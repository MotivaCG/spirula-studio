"""Export PLY sequences to .vgs with VGSEditor's own writer (the size to compare with Gracia),
through its automation bridge; the editor is closed at the end.
Usage: vgsedit_export.py <out dir> <tag>=<first frame ply> ...  (writes <out dir>/<tag>.vgs)"""
import json, os, socket, subprocess, sys, time
from pathlib import Path

EXE = r"D:\Trabajos\THE4DSCANNER\VGSFileFormat\editor\build\cmake-msvc\Release\VGSEditor.exe"
SESS = Path(os.environ["TEMP"]) / "vgs_mcp_export"
out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
runs = [a.split("=", 1) for a in sys.argv[2:]]


def call(method, args=None, timeout=120):
    req = json.dumps({"token": D["token"], "method": method, "arguments": args or {}}).encode() + b"\n"
    for _ in range(300):  # the bridge listens a moment after the descriptor appears
        try: s = socket.create_connection(("127.0.0.1", D["port"]), timeout=timeout); break
        except ConnectionRefusedError: time.sleep(0.1)
    with s:
        s.sendall(req)
        with s.makefile("rb") as f: line = f.readline()
    r = json.loads(line)
    if not r.get("ok"): raise RuntimeError(f"{method}: {r.get('error')}")
    return r["result"]


def settle():
    while True:
        s = call("state")
        if s.get("error"): raise RuntimeError(s["error"])
        if not s.get("loading") and not s.get("processing"): return s
        time.sleep(0.2)


SESS.mkdir(exist_ok=True)
proc = subprocess.Popen([EXE, "--mcp-session-dir", str(SESS)])
try:
    D = None
    while D is None:
        time.sleep(0.2)
        for p in SESS.glob("*.json"):
            d = json.loads(p.read_text(encoding="utf-8"))
            if d.get("pid") == proc.pid: D = d
    for tag, ply in runs:
        call("open", {"path": ply, "discard_unsaved": True}); s = settle()
        cs = call("project")["captureSettings"]
        print(tag, "frames", s.get("frames"), "chunks", s.get("chunk_count"), "shDegree", cs.get("shDegree"), flush=True)
        target = out / f"{tag}.vgs"
        job = call("export", {"path": str(target), "overwrite": True})["job_id"]
        while True:
            st = call("export_status", {"job_id": job})
            if st.get("state") in ("done", "failed", "cancelled") or st.get("status") in ("done", "failed", "cancelled"): break
            time.sleep(1)
        print(tag, "export", st.get("state") or st.get("status"), "bytes", target.stat().st_size if target.exists() else None, flush=True)
finally:
    proc.terminate()
