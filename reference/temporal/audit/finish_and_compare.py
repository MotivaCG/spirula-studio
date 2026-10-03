"""Finish the serial GPU gate, freeze B11 and compare compressed VGS variants."""
import argparse
import datetime as dt
import json
import msvcrt
from pathlib import Path
import subprocess
import sys
import time
from freeze_reference import freeze, digest

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
TC = REPO / 'outputs/tc'


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--codec', type=Path, required=True)
    p.add_argument('--ready', type=Path, required=True)
    a = p.parse_args()
    a.out.mkdir(parents=True, exist_ok=False)
    state = dict(status='WAITING', phase='B10_B11_AND_TOOL_VALIDATION', completed=[],
                 started_utc=dt.datetime.now(dt.timezone.utc).isoformat())
    def save():
        target = a.out / 'status.json'
        temp = target.with_suffix('.tmp')
        temp.write_text(json.dumps(state, indent=2), encoding='utf-8')
        temp.replace(target)
    def run(name, cmd):
        state.update(status='RUNNING', phase=name)
        save()
        with open(a.out / f'{name}.log', 'w', encoding='utf-8') as log:
            subprocess.run([str(x) for x in cmd], cwd=REPO, stdout=log,
                           stderr=subprocess.STDOUT, check=True)
        state['completed'].append(name)
        save()
    save()
    lock = None
    try:
        deadline = time.monotonic() + 24 * 3600
        while True:
            b10 = json.loads((TC / 'B10_20260927_battery/status.json').read_text())
            queue = json.loads((TC / 'B11_20260927_queue_status.json').read_text())
            if b10['status'] == 'ERROR' or queue['state'] in ('ERROR', 'SKIPPED_AFTER_ERROR', 'TIMEOUT'):
                raise RuntimeError('Training prerequisite failed; retain partial artifacts')
            status = TC / 'B11_20260927_battery/status.json'
            b11 = json.loads(status.read_text()) if status.exists() else {}
            if b11.get('status') == 'ERROR':
                raise RuntimeError('B11 failed')
            if b11.get('status') == 'COMPLETE' and a.ready.exists():
                break
            if time.monotonic() > deadline:
                raise TimeoutError('Training/tool readiness timeout')
            time.sleep(60)
        readiness = json.loads(a.ready.read_text())
        if readiness['status'] != 'PASS' or readiness['codec_sha256'] != digest(a.codec):
            raise RuntimeError('Codec validation does not match executable')
        lock = open(TC / 'temporal_audit_gpu.lock', 'a+b')
        lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        gpu = REPO / 'build_tc/engine_temporal_birth.exe'
        state['sha256'] = {str(p): digest(p) for p in [a.codec, gpu, HERE / 'finish_and_compare.py']}
        run('birth_gpu', [gpu])
        metrics = b11['completed'][0]
        cov = metrics['coverage']['76']['coverage']
        if not (metrics['fit_mean'] >= 30.5 and metrics['fit_final'] >= 30.0 and
                metrics['flicker'] <= 9.5 and cov >= .88):
            state['quality_metrics'] = metrics
            raise RuntimeError('B11 failed predeclared quality gate; do not freeze/promote automatically')
        state['reference_run'] = metrics['run']
        state['reference_limit'] = 'One corrected full run; robustness derives from B8R, not repeated B11 seeds'
        state['phase'] = 'FREEZING'
        save()
        reference = a.out / 'reference'
        manifest = freeze(TC / metrics['run'], reference)
        if len(manifest['frames']) != 32:
            raise RuntimeError('Expected full 45-76 sequence')
        state['completed'].append('reference')
        variants = [('samples', 4), ('legacy', 1), ('adaptive', 4), ('predictive', 4)]
        for mode, chunk in variants:
            run(mode, [a.codec, reference, a.out / mode, mode, chunk])
        run('render_compare', [sys.executable, HERE / 'compare_codec_renders.py', '--root', a.out])
        run('web_compare', [sys.executable, HERE / 'run_web_codec.py', '--root', a.out])
        state.update(status='COMPLETE', phase='READY_FOR_REVIEW')
    except BaseException as exc:
        state.update(status='ERROR', error=str(exc))
        raise
    finally:
        if lock:
            lock.seek(0)
            msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
            lock.close()
        save()


if __name__ == '__main__':
    main()
