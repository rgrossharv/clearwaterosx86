#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
PROFILE_DIR="$PROJECT_ROOT/profile-creedence"
WORK_DIR="$PROJECT_ROOT/work-creedence"
OUTPUT_DIR="$PROJECT_ROOT/build-creedence"
CACHE_DIR="$PROJECT_ROOT/cache/pacman"
IMAGE_NAME="localhost/clearwater-builder:latest"

required_files=(
    "$PROJECT_ROOT/Containerfile"
    "$PROFILE_DIR/profiledef.sh"
    "$PROFILE_DIR/packages.x86_64"
    "$PROFILE_DIR/pacman.conf"
)

for required_file in "${required_files[@]}"; do
    if [[ ! -e "$required_file" ]]; then
        echo "Error: required file missing: $required_file" >&2
        exit 1
    fi
done

if ! sudo podman image exists "$IMAGE_NAME"; then
    cat >&2 <<EOF
Error: required rootful Podman image is missing: $IMAGE_NAME

Build it first with:
  sudo podman build --network=host -t $IMAGE_NAME "$PROJECT_ROOT"
EOF
    exit 1
fi

restore_ownership() {
    local uid gid
    uid="${SUDO_UID:-$(id -u)}"
    gid="${SUDO_GID:-$(id -g)}"

    if [[ "$uid" != "0" ]]; then
        if ! sudo chown -R "$uid:$gid" "$WORK_DIR" "$OUTPUT_DIR" "$CACHE_DIR"; then
            echo "Warning: failed to restore ownership of build artifacts to $uid:$gid" >&2
        fi
    fi
}

reset_work_dir() {
    case "$WORK_DIR" in
        "$PROJECT_ROOT"/work-creedence)
            sudo rm -rf --one-file-system "$WORK_DIR"
            mkdir -p "$WORK_DIR"
            ;;
        *)
            echo "Error: refusing to remove unexpected work directory: $WORK_DIR" >&2
            exit 1
            ;;
    esac
}

trap restore_ownership EXIT

mkdir -p "$OUTPUT_DIR" "$CACHE_DIR"
reset_work_dir

sudo podman run --rm \
    --network=host \
    --pull=never \
    --privileged \
    --security-opt label=disable \
    -v "$PROFILE_DIR:/clearwater/profile:ro" \
    -v "$WORK_DIR:/clearwater/work" \
    -v "$OUTPUT_DIR:/clearwater/build" \
    -v "$CACHE_DIR:/var/cache/pacman/pkg" \
    "$IMAGE_NAME" \
    mkarchiso \
        -v \
        -w /clearwater/work \
        -o /clearwater/build \
        /clearwater/profile

iso_path="$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | awk 'NR == 1 {print $2}')"

if [[ -z "$iso_path" ]]; then
    echo "Error: mkarchiso completed but no ISO was found in $OUTPUT_DIR" >&2
    exit 1
fi

sha256sum "$iso_path" > "$iso_path.sha256"

echo
echo "Creedence build complete."
echo "ISO: $iso_path"
echo "SHA-256: $iso_path.sha256"
