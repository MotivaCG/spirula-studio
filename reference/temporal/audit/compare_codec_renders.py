"""Compare decoded VGS against frozen PLY using shared cameras and frozen color fits."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import numpy as np
from PIL import Image
from freeze_reference import digest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import evaluate as e


def psnr(error):
    return float(-10 * np.log10(max(float(np.mean(error * error)), 1e-12)))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, required=True)
    a = p.parse_args()
    manifest = json.loads((a.root / 'reference/manifest.json').read_text())
    run = Path(manifest['source']).name
    tc = HERE.parents[2] / 'outputs/tc'
    modes = ['legacy', 'adaptive', 'predictive']
    render_root = (a.root / 'renders').resolve()
    render_root.mkdir(exist_ok=True)
    dirs = {'reference': {}, **{m: {} for m in modes}}
    for f in manifest['frames']:
        frame = f['source_frame']
        if digest(a.root / 'samples/decoded' / f['file']) != f['sha256']:
            raise ValueError('Lossless sample baseline changed PLY bytes')
        dirs['reference'][frame] = tc / 'q' / f'{run}.seq_{frame}'
        for mode in modes:
            ply = (a.root / mode / 'decoded' / f['file']).resolve()
            name = f'{mode}_{frame}'
            target = render_root / name
            if target.exists():
                raise FileExistsError(f'Render retry requires a new output: {target}')
            with open(render_root / f'{name}.log', 'w', encoding='utf-8') as log:
                subprocess.run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                                str(HERE / 'render_codec.ps1'), '-Ply', str(ply), '-Frame', str(frame),
                                '-Root', str(render_root), '-Name', name], stdout=log, stderr=subprocess.STDOUT, check=True)
            dirs[mode][frame] = target
    views = {m: {f: e.camera_views(str(d)) for f, d in dd.items()} for m, dd in dirs.items()}
    shared = set.intersection(*[set(v) for dd in views.values() for v in dd.values()])
    if not shared:
        raise ValueError('No shared fixed camera across every source/decoded frame')
    frames = [f['source_frame'] for f in manifest['frames']]
    result = dict(cameras=sorted(shared), omitted_camera_count=len(set.union(*[set(v) for dd in views.values() for v in dd.values()]) - shared),
                  color_policy='per-camera affine fit over reference sequence, frozen for all codecs', modes={})
    rows = {m: [] for m in dirs}
    pairs = {m: [] for m in dirs}
    load = lambda p: np.asarray(Image.open(p).convert('RGB'), np.float32) / 255
    for cam in sorted(shared):
        moments = np.zeros((3, 5), np.float64)
        for f in frames:
            idx, mask = views['reference'][f][cam]
            q = dirs['reference'][f]
            r, g = load(q / f'eval-render-{idx:05d}.png'), load(q / f'eval-gt-{idx:05d}.png')
            m = np.asarray(Image.open(mask).convert('L').resize(r.shape[1::-1])) > 127
            x, y = r[m].astype(np.float64), g[m].astype(np.float64)
            moments[:, 0] += len(x)
            moments[:, 1] += x.sum(0)
            moments[:, 2] += y.sum(0)
            moments[:, 3] += (x*x).sum(0)
            moments[:, 4] += (x*y).sum(0)
        n, sx, sy, sxx, sxy = moments.T
        slope = (sxy - sx*sy/n) / np.maximum(sxx-sx*sx/n, 1e-12)
        offset = (sy-slope*sx)/n
        previous = None
        for f in frames:
            idx, mask = views['reference'][f][cam]
            q = dirs['reference'][f]
            gt, ref = load(q / f'eval-gt-{idx:05d}.png'), load(q / f'eval-render-{idx:05d}.png')
            mask = np.asarray(Image.open(mask).convert('L').resize(ref.shape[1::-1])) > 127
            current = dict(gt=gt, mask=mask, renders={})
            for mode in dirs:
                idx = views[mode][f][cam][0]
                q = dirs[mode][f]
                raw = load(q / f'eval-render-{idx:05d}.png')
                if not np.array_equal(load(q / f'eval-gt-{idx:05d}.png'), gt):
                    raise ValueError(f'Camera/ground truth mismatch: {mode} {f} {cam}')
                corrected = (raw*slope+offset).astype(np.float32)
                current['renders'][mode] = corrected
                rows[mode].append(dict(frame=f, camera=cam, fit=psnr((corrected-gt)[mask]),
                                      detail=psnr(((corrected-e.box_blur(corrected))-(gt-e.box_blur(gt)))[mask]),
                                      fidelity_raw=psnr((raw-ref)[mask]), raw_max=float(np.abs(raw-ref)[mask].max())))
                if previous:
                    m = previous['mask'] | mask
                    w = e.blocks(m[..., None].astype(np.float32))[..., 0]
                    ok = w > .5
                    d = (corrected-previous['renders'][mode])-(gt-previous['gt'])
                    regional = e.blocks(d*m[..., None]) / np.maximum(w[..., None], 1e-6)
                    pairs[mode].append(dict(frame=f-1, camera=cam, flicker=float(np.abs(regional[ok]).mean()*1000)))
            previous = current
    for mode in dirs:
        rr, pp = rows[mode], pairs[mode]
        result['modes'][mode] = dict(fit_mean=float(np.mean([r['fit'] for r in rr])),
                                    fit_final=float(np.mean([r['fit'] for r in rr if r['frame']==frames[-1]])),
                                    detail_mean=float(np.mean([r['detail'] for r in rr])),
                                    flicker=float(np.mean([r['flicker'] for r in pp])),
                                    fidelity_raw_mean=float(np.mean([r['fidelity_raw'] for r in rr])),
                                    raw_max=max(r['raw_max'] for r in rr),
                                    worst_pairs=sorted(pp, key=lambda r: r['flicker'], reverse=True)[:10])
    ref = result['modes']['reference']
    for mode in modes:
        m = result['modes'][mode]
        m['fit_loss'] = ref['fit_mean']-m['fit_mean']
        m['final_loss'] = ref['fit_final']-m['fit_final']
        m['detail_loss'] = ref['detail_mean']-m['detail_mean']
        m['added_flicker'] = m['flicker']-ref['flicker']
        m['budget_pass'] = max(m['fit_loss'], m['final_loss'], m['detail_loss']) <= .2 and m['added_flicker'] <= .5
    (a.root / 'render_metrics.json').write_text(json.dumps(result, indent=2, allow_nan=False), encoding='utf-8')
    (a.root / 'render_details.json').write_text(json.dumps(dict(frames=rows, pairs=pairs), allow_nan=False), encoding='utf-8')
    print(json.dumps(result['modes'], allow_nan=False))


if __name__ == '__main__':
    main()
