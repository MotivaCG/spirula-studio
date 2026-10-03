"""Create analytic native-codec fixtures, including generation reuse."""
import argparse
from pathlib import Path
import numpy as np


def create(out):
    out.mkdir(parents=True, exist_ok=False)
    names = ['x', 'y', 'z', 'nx', 'ny', 'nz', 'f_dc_0', 'f_dc_1', 'f_dc_2']
    names += [f'f_rest_{i}' for i in range(9)]
    names += ['opacity', 'scale_0', 'scale_1', 'scale_2', 'rot_0', 'rot_1', 'rot_2', 'rot_3']
    count = 257
    header = ('ply\nformat binary_little_endian 1.0\nelement vertex ' + str(count) + '\n' +
              ''.join(f'property float {p}\n' for p in names) + 'end_header\n').encode('ascii')
    for frame in range(8):
        a = np.zeros((count, len(names)), dtype='<f4')
        a[:, 0] = np.arange(count) / 100 + frame * .01
        a[:, 1] = frame * frame * .003
        a[:, 2] = 3
        a[:, 6:9] = [.2, .5, .7]
        a[:, 9:18] = np.arange(9) * .01 + frame * .001
        a[:, 18] = 1
        a[:, 19:22] = [-3 + .01 * frame, -2, -4]
        a[:, 22] = np.cos(frame * .1)
        a[:, 25] = np.sin(frame * .1)
        if frame >= 3:
            a[0, 0] += 10
        (out / f'{frame:04d}.ply').write_bytes(header + a.tobytes())
    (out / 'birth_events.tsv').write_text('3\t0\t1\n', encoding='ascii')
    (out / 'timebase.txt').write_text('1001 30000\n', encoding='ascii')


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('out', type=Path)
    create(p.parse_args().out)
