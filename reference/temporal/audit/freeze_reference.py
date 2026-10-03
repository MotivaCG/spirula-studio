"""Freeze exact PLY bytes, row generations and explicit timing for codec experiments."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from run_audit import read_ply


def digest(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1024 * 1024), b''):
            h.update(b)
    return h.hexdigest()


def freeze(source, out, first=45, numerator=1, denominator=30):
    if out.exists():
        raise FileExistsError(out)
    paths = sorted(source.glob('frames/[0-9][0-9][0-9]/splat.ply'))
    events = source / 'frames/birth_events.tsv'
    if not paths or not events.exists():
        raise ValueError('A complete sequence with generation events is required')
    out.mkdir(parents=True)
    records = []
    for slot, path in enumerate(paths):
        if int(path.parent.name) != slot:
            raise ValueError('Noncontiguous frame slots')
        props, data = read_ply(path)
        if slot == 0:
            schema, rows = props, len(data)
        if props != schema or len(data) != rows:
            raise ValueError('Schema/count changed')
        target = out / f'{first + slot:04d}.ply'
        shutil.copyfile(path, target)
        sha = digest(path)
        if digest(target) != sha:
            raise ValueError('Reference copy differs')
        records.append(dict(slot=slot, source_frame=first + slot, tick=slot,
                            file=target.name, sha256=sha, bytes=target.stat().st_size))
    shutil.copyfile(events, out / 'birth_events.tsv')
    (out / 'timebase.txt').write_text(f'{numerator} {denominator}\n', encoding='ascii')
    manifest = dict(status='FROZEN', source=str(source.resolve()), frames=records,
                    rows=rows, properties=schema, timebase=[numerator, denominator],
                    timebase_provenance='Benchmark timebase; original capture frame rate not independently verified',
                    duration_ticks=len(paths), terminal_policy='hold final frame for one tick',
                    identity='(source row, generation); generation zero before first event',
                    events_sha256=digest(events), quaternion='wxyz; original PLY values',
                    scale='log', opacity='logit', sh='PLY channel-major; unmodified',
                    coordinates='unchanged from source training dataset',
                    note='Byte-exact reference. Codec outputs are evaluated against this archive.')
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    return manifest


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    print(json.dumps({'status': freeze(a.source, a.out)['status'], 'out': str(a.out)}))
