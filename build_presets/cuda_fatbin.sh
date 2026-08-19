#!/usr/bin/env bash
# CUDA backend, CLI only, fat binary: Turing through Blackwell plus PTX.
# Patent-encumbered modules stay out (see docs/build.md, SS_ENABLE_PATENTED).

cd "$(dirname "$0")/.." || exit 1
export SS_BUILD_DIR="${SS_BUILD_DIR:-build_cuda_fatbin}"
export SS_CUDA_FATBIN=1
exec bash build_develop.bash -DSS_BACKEND=cuda -DSS_BUILD_CLI=ON -DSS_BUILD_GUI=OFF -DSS_ENABLE_PATENTED=OFF "$@"
