#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

fail() {
    echo "Error: $*" >&2
    exit 1
}

required_project_files=(
    "$PROJECT_ROOT/Containerfile"
    "$PROJECT_ROOT/buildcwos"
    "$PROJECT_ROOT/buildcreedence"
    "$PROJECT_ROOT/flashcwos"
    "$PROJECT_ROOT/flashcreedence"
    "$PROJECT_ROOT/scripts/build-iso.sh"
    "$PROJECT_ROOT/scripts/build-creedence.sh"
    "$PROJECT_ROOT/scripts/buildcwos"
    "$PROJECT_ROOT/scripts/flash-usb.sh"
    "$PROJECT_ROOT/scripts/flash-creedence.sh"
    "$PROJECT_ROOT/scripts/flashcwos"
    "$PROJECT_ROOT/scripts/qemu-vnc.sh"
)

common_profile_files=(
    "profiledef.sh"
    "packages.x86_64"
    "pacman.conf"
    "airootfs/etc/os-release"
    "airootfs/etc/hostname"
    "airootfs/etc/motd"
    "airootfs/etc/modprobe.d/clearwater-bcm43602-wifi.conf"
    "airootfs/etc/profile.d/clearwater-fastfetch.sh"
    "airootfs/etc/calamares/settings.conf"
    "airootfs/etc/calamares/branding/clearwateros/branding.desc"
    "airootfs/etc/calamares/branding/clearwateros/clearwater-logo.svg"
    "airootfs/etc/calamares/branding/clearwateros/clearwater-welcome.svg"
    "airootfs/etc/calamares/modules/bootloader.conf"
    "airootfs/etc/calamares/modules/displaymanager.conf"
    "airootfs/etc/calamares/modules/services-systemd.conf"
    "airootfs/etc/calamares/modules/shellprocess-clearwater-cleanup.conf"
    "airootfs/etc/calamares/modules/unpackfs.conf"
    "airootfs/etc/calamares/modules/users.conf"
    "airootfs/etc/calamares/modules/welcome.conf"
    "airootfs/etc/polkit-1/rules.d/49-clearwater-calamares.rules"
    "airootfs/etc/skel/.bashrc"
    "airootfs/etc/skel/Desktop/calamares.desktop"
    "airootfs/etc/sddm.conf.d/10-clearwater-live.conf"
    "airootfs/etc/skel/.config/konsolerc"
    "airootfs/etc/skel/.local/share/konsole/ClearwaterOS.profile"
    "airootfs/etc/sudoers.d/10-clearwater-live"
    "airootfs/etc/systemd/system/clearwater-bcm43602-wifi.service"
    "airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
    "airootfs/etc/systemd/system/multi-user.target.wants/bluetooth.service"
    "airootfs/etc/systemd/system/multi-user.target.wants/clearwater-bcm43602-wifi.service"
    "airootfs/etc/sysusers.d/clearwater.conf"
    "airootfs/etc/tmpfiles.d/clearwater.conf"
    "airootfs/etc/xdg/kdeglobals"
    "airootfs/etc/xdg/fastfetch/config.jsonc"
    "airootfs/etc/xdg/plasmarc"
    "airootfs/usr/lib/clearwateros/fix-bcm43602-wifi"
    "airootfs/usr/share/clearwateros/fastfetch-logo.txt"
    "airootfs/usr/local/bin/install-clearwateros"
    "airootfs/usr/share/applications/calamares.desktop"
    "airootfs/usr/share/plasma/look-and-feel/org.clearwateros.desktop/contents/defaults"
    "airootfs/usr/share/plasma/look-and-feel/org.clearwateros.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
    "airootfs/usr/share/plasma/look-and-feel/org.clearwateros.desktop/metadata.json"
    "airootfs/usr/share/wallpapers/ClearwaterOS/contents/images/clearwater.jpg"
    "airootfs/usr/share/wallpapers/ClearwaterOS/metadata.json"
)

consumer_only_files=(
    "airootfs/etc/systemd/system/clearwater-flathub.service"
    "airootfs/etc/systemd/system/multi-user.target.wants/avahi-daemon.service"
    "airootfs/etc/systemd/system/multi-user.target.wants/clearwater-flathub.service"
    "airootfs/etc/systemd/system/multi-user.target.wants/cups.service"
    "airootfs/etc/systemd/system/multi-user.target.wants/firewalld.service"
    "airootfs/etc/systemd/system/sockets.target.wants/avahi-daemon.socket"
)

check_required_file() {
    local file="$1"
    [[ -e "$file" || -L "$file" ]] || fail "required file missing: $file"
}

check_profile() {
    local profile_dir="$1"
    local expected_name="$2"

    for relpath in "${common_profile_files[@]}"; do
        check_required_file "$profile_dir/$relpath"
    done

    duplicates="$(awk 'NF && $1 !~ /^#/ {print $1}' "$profile_dir/packages.x86_64" | sort | uniq -d)"
    [[ -z "$duplicates" ]] || fail "duplicate packages found in $profile_dir: $duplicates"

    while IFS= read -r link; do
        target="$(readlink "$link")"
        if [[ "$target" == /* ]]; then
            case "$target" in
                /etc/systemd/system/*)
                    [[ -e "$profile_dir/airootfs$target" ]] || fail "broken systemd symlink: $link -> $target"
                    ;;
                /usr/lib/systemd/system/*|/usr/share/zoneinfo/*|/run/systemd/resolve/*|/dev/null)
                    ;;
                *)
                    [[ -e "$profile_dir/airootfs$target" ]] || fail "unexpected absolute symlink target: $link -> $target"
                    ;;
            esac
        else
            [[ -e "$(dirname "$link")/$target" ]] || fail "broken systemd symlink: $link -> $target"
        fi
    done < <(find "$profile_dir/airootfs/etc/systemd" -type l -print)

    grep -q '^iso_name=' "$profile_dir/profiledef.sh" || fail "iso_name missing from $profile_dir/profiledef.sh"
    grep -q '^iso_publisher=' "$profile_dir/profiledef.sh" || fail "iso_publisher missing from $profile_dir/profiledef.sh"
    grep -q '^iso_application=' "$profile_dir/profiledef.sh" || fail "iso_application missing from $profile_dir/profiledef.sh"
    grep -q "^NAME=\"$expected_name\"$" "$profile_dir/airootfs/etc/os-release" || fail "$expected_name NAME missing from $profile_dir/airootfs/etc/os-release"
    grep -q '^ID=clearwater$' "$profile_dir/airootfs/etc/os-release" || fail "ClearwaterOS ID missing from $profile_dir/airootfs/etc/os-release"
}

for required_file in "${required_project_files[@]}"; do
    check_required_file "$required_file"
done

for relpath in "${consumer_only_files[@]}"; do
    check_required_file "$PROJECT_ROOT/profile/$relpath"
done

check_profile "$PROJECT_ROOT/profile" "ClearwaterOS"
check_profile "$PROJECT_ROOT/profile-creedence" "ClearwaterOS Creedence"

while IFS= read -r script; do
    bash -n "$script"
done < <(find "$PROJECT_ROOT" \
    -path "$PROJECT_ROOT/.git" -prune -o \
    -path "$PROJECT_ROOT/build" -prune -o \
    -path "$PROJECT_ROOT/build-creedence" -prune -o \
    -path "$PROJECT_ROOT/cache" -prune -o \
    -path "$PROJECT_ROOT/work" -prune -o \
    -path "$PROJECT_ROOT/work-creedence" -prune -o \
    -type f -perm -0100 -print)

tracked_generated="$(git -C "$PROJECT_ROOT" ls-files build build-creedence cache work work-creedence '*.iso' '*.img' '*.qcow2')"
[[ -z "$tracked_generated" ]] || fail "generated build files are tracked by Git: $tracked_generated"

echo "Profile checks passed."
