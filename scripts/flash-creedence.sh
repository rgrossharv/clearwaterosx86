#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
TARGET_DEVICE="${1:-/dev/sdc}"
EXPECTED_MODEL="${EXPECTED_MODEL:-Cruzer Glide}"
OUTPUT_DIR="$PROJECT_ROOT/build-creedence"

latest_iso() {
    find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' \
        | sort -nr \
        | awk 'NR == 1 {print $2}'
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

[[ -b "$TARGET_DEVICE" ]] || fail "target is not a block device: $TARGET_DEVICE"

device_type="$(lsblk -dn -o TYPE "$TARGET_DEVICE")"
device_transport="$(lsblk -dn -o TRAN "$TARGET_DEVICE")"
device_model="$(lsblk -dn -o MODEL "$TARGET_DEVICE" | sed 's/[[:space:]]*$//')"

[[ "$device_type" == "disk" ]] || fail "$TARGET_DEVICE is not a whole disk"
[[ "$device_transport" == "usb" ]] || fail "$TARGET_DEVICE is not a USB disk"

if [[ -n "$EXPECTED_MODEL" && "$device_model" != *"$EXPECTED_MODEL"* ]]; then
    fail "$TARGET_DEVICE model is '$device_model', expected something containing '$EXPECTED_MODEL'"
fi

ISO_PATH="$(latest_iso)"
[[ -n "$ISO_PATH" && -f "$ISO_PATH" ]] || fail "no Creedence ISO found in $OUTPUT_DIR"

echo "ISO:    $ISO_PATH"
echo "Target: $TARGET_DEVICE"
lsblk -o NAME,PATH,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS,FSTYPE,LABEL "$TARGET_DEVICE"
echo
echo "This will overwrite every partition on $TARGET_DEVICE."
read -r -p "Type FLASH to continue: " answer
[[ "$answer" == "FLASH" ]] || fail "aborted"

mapfile -t mounted_parts < <(lsblk -ln -o PATH "$TARGET_DEVICE" | tail -n +2)
for part in "${mounted_parts[@]}"; do
    sudo umount "$part" 2>/dev/null || true
done
sudo umount "$TARGET_DEVICE" 2>/dev/null || true

sudo dd if="$ISO_PATH" of="$TARGET_DEVICE" bs=4M status=progress conv=fsync
sync

echo
echo "Flash complete."
echo "Unmounting and powering off $TARGET_DEVICE..."

udevadm settle 2>/dev/null || true
sleep 2

mapfile -t flashed_parts < <(lsblk -ln -o PATH "$TARGET_DEVICE" | tail -n +2)
for part in "${flashed_parts[@]}"; do
    udisksctl unmount -b "$part" 2>/dev/null || true
done

if udisksctl power-off -b "$TARGET_DEVICE"; then
    echo "USB drive powered off. It is safe to remove."
else
    echo "Warning: automatic power-off failed. Check mounts with:" >&2
    echo "  lsblk -o NAME,PATH,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS,FSTYPE,LABEL $TARGET_DEVICE" >&2
    echo "Then retry:" >&2
    echo "  udisksctl power-off -b $TARGET_DEVICE" >&2
fi
