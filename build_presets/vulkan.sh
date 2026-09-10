#!/usr/bin/env bash
# Vulkan backend, CLI + GUI. No CUDA toolkit needed.
# Patent-encumbered modules stay out (see docs/build.md, SS_ENABLE_PATENTED).

cd "$(dirname "$0")/.." || exit 1
export SS_BUILD_DIR="${SS_BUILD_DIR:-build_vulkan}"
exec bash build_develop.bash -DSS_BACKEND=vulkan -DSS_BUILD_GUI=ON -DSS_ENABLE_PATENTED=OFF "$@"
