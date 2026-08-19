# `build_presets/`

The three builds this project is actually shipped and developed in, one script
per platform. Each one forwards to `build_develop.bash` / `build_develop.bat`,
so the codegen and the five lints still run; the preset only fixes the flags
that are easy to get wrong.

| preset | backend | GUI | build tree |
|---|---|---|---|
| `vulkan` | Vulkan | yes | `build_vulkan/` |
| `cuda` | CUDA, this machine's GPU | yes | `build_cuda/` |
| `cuda_fatbin` | CUDA, Turing → Blackwell + PTX | no | `build_cuda_fatbin/` |

```bash
bash build_presets/vulkan.sh            # Linux / macOS
```
```bat
build_presets\vulkan.bat                 :: Windows
```

Extra arguments are passed through to CMake, so
`bash build_presets/cuda.sh -DSS_BUILD_SFM=ON` works.

**Separate trees.** Each preset sets `SS_BUILD_DIR`, because switching backend
or architecture list in one tree throws the CMake cache away and rebuilds
everything. Override it (`SS_BUILD_DIR=build bash build_presets/cuda.sh`) if
you would rather they shared one.

**`SS_ENABLE_PATENTED=OFF` in all three**, spelled out rather than left to the
default: it gates `src/video/` (H.264 / H.265 / AV1), the only patent-
encumbered code in the tree, and everything that wanted it falls back to
ffmpeg. `docs/build.md` has the reasoning.

**`cuda_fatbin` is for packaging, not for iterating.** Seven architectures is
seven compilations of every kernel, over a matrix that is already large. It
drops the GUI for the same reason. Nothing below Turing (7.5) runs on the
result — PTX only JITs forward — so a Pascal target has to be named:
`SS_CUDA_ARCHS="6.1 7.5 8.6" bash build_presets/cuda_fatbin.sh`.
