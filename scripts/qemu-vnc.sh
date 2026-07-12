#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
ISO_PATH="${1:-}"

if [[ -z "$ISO_PATH" ]]; then
    ISO_PATH="$(find "$PROJECT_ROOT/build" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | awk 'NR == 1 {print $2}')"
fi

if [[ -z "$ISO_PATH" || ! -f "$ISO_PATH" ]]; then
    echo "Usage: $0 /path/to/clearwateros.iso" >&2
    exit 1
fi

exec qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -cpu host \
    -smp 2 \
    -boot d \
    -cdrom "$ISO_PATH" \
    -display none \
    -vnc 127.0.0.1:1 \
    -device virtio-vga \
    -device ich9-intel-hda \
    -device hda-duplex \
    -nic user,model=virtio-net-pci
