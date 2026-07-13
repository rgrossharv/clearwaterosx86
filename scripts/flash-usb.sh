#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
TARGET_DEVICE="${1:-/dev/sdc}"
EXPECTED_MODEL="${EXPECTED_MODEL:-Cruzer Glide}"

latest_iso() {
    find "$PROJECT_ROOT/build" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' \
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
[[ -n "$ISO_PATH" && -f "$ISO_PATH" ]] || fail "no ISO found in $PROJECT_ROOT/build"

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
echo "Verify with:"
echo "  lsblk -o NAME,PATH,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS,FSTYPE,LABEL $TARGET_DEVICE"
echo
echo "Eject with:"
echo "  udisksctl unmount -b ${TARGET_DEVICE}1"
echo "  udisksctl unmount -b ${TARGET_DEVICE}2"
echo "  udisksctl power-off -b $TARGET_DEVICE"
