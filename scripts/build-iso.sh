#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_DIR="$PROJECT_ROOT/profile"
WORK_DIR="$PROJECT_ROOT/work"
OUTPUT_DIR="$PROJECT_ROOT/build"
CACHE_DIR="$PROJECT_ROOT/cache/pacman"

if [[ ! -f "$PROFILE_DIR/profiledef.sh" ]]; then
    echo "Error: Archiso profile not found at $PROFILE_DIR" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR" "$CACHE_DIR"
rm -rf "$WORK_DIR"

podman run --rm \
    --privileged \
    --security-opt label=disable \
    -v "$PROFILE_DIR:/clearwater/profile:ro" \
    -v "$WORK_DIR:/clearwater/work" \
    -v "$OUTPUT_DIR:/clearwater/build" \
    -v "$CACHE_DIR:/var/cache/pacman/pkg" \
    clearwater-builder \
    mkarchiso \
        -v \
        -w /clearwater/work \
        -o /clearwater/build \
        /clearwater/profile

echo
echo "Build complete:"
find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.iso' -print
