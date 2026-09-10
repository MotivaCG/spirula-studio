#!/usr/bin/env bash
# CUDA backend, CLI + GUI, built for this machine's GPU only.
# Patent-encumbered modules stay out (see docs/build.md, SS_ENABLE_PATENTED).

cd "$(dirname "$0")/.." || exit 1
export SS_BUILD_DIR="${SS_BUILD_DIR:-build_cuda}"
exec bash build_develop.bash -DSS_BACKEND=cuda -DSS_BUILD_GUI=ON -DSS_ENABLE_PATENTED=OFF "$@"
