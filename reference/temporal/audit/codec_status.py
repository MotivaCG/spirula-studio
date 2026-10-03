"""Print compact training/codec status without loading logs or large manifests."""
import json
from pathlib import Path

tc = Path(__file__).resolve().parents[3] / 'outputs/tc'
out = {}
for name in ('B10_20260927_battery', 'B11_20260927_battery', 'C12_20260927'):
    path = tc / name / 'status.json'
    if not path.exists():
        continue
    s = json.loads(path.read_text())
    row = {k: s[k] for k in ('status', 'phase', 'error', 'reference_run') if k in s}
    row['completed'] = [{k: r[k] for k in ('run', 'fit_mean', 'fit_final', 'detail_mean', 'flicker')}
                        if isinstance(r, dict) else r for r in s.get('completed', [])]
    out[name] = row
root = tc / 'C12_20260927'
out['render_progress'] = {'complete': len(list((root / 'renders').glob('*/eval_views.txt'))),
                          'expected': 96}
for mode in ('samples', 'legacy', 'adaptive', 'predictive'):
    p = root / mode / 'metrics.json'
    if p.exists():
        m = json.loads(p.read_text())
        out[mode] = {k: m[k] for k in ('bytes', 'sample_exact', 'parameter_max_abs', 'chunk_decode_p95_ms', 'largest_gpu_chunk_bytes')}
for name in ('render_metrics', 'web_metrics'):
    out[name] = str(root / (name + '.json')) if (root / (name + '.json')).exists() else 'PENDING'
print(json.dumps(out, indent=2))
